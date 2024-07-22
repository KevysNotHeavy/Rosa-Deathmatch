---Stand-alone version of the speaker libary for jpxs.pvp.
---this is a modified verson of my normal speaker libary to not require external libaries.
---2024 @gart
---v2.3 standalone
---@class Speaker_Standalone
---@field public _baseItem Item
---@field public player Player
---@field public currentPath string
---@field public encoder OpusEncoder
---@field public status Speaker_Standalone_Status
---@field public meta {title: string, author: string, duration: number, id: string}
---@field public currentDuration number
---@field public errorFrames  number
---@field public hasReloadedEncoder boolean
---@field public class string
local Speaker = {
	_v = "2.3_STANDALONE",
}

---@enum Speaker_Standalone_Status
Speaker.SPEAKER_STATUS = {
	["IDLE"] = 0,
	["PLAYING"] = 1,
	["PAUSED"] = 2,
	["FINISHED"] = 3,
	["DESTROYED"] = 4,
}

---@type {[integer]: Speaker_Standalone}
Speaker.speakers = {}

Speaker.__index = Speaker

---Create a new speaker on an item.
---@param item Item
function Speaker.create(item)
	local newSpeaker = setmetatable({
		class = "Speaker",
		_baseItem = item,
		player = nil,
		currentPath = nil,
		encoder = nil,
		errorFrames = 0,
		hasReloadedEncoder = false,
		status = Speaker.SPEAKER_STATUS.IDLE,
		meta = { title = nil, author = nil, duration = nil, id = nil },
	}, Speaker)

	local playerIndex = Speaker.getFreePlayerIndex()
	assert(playerIndex, "No free player index")

	newSpeaker.player = players[playerIndex]

	local encoder = OpusEncoder.new()
	encoder.bitRate = 48000

	newSpeaker.encoder = encoder

	newSpeaker.player.data.isSpeaker = true
    if newSpeaker._baseItem then
		newSpeaker._baseItem.data.Speaker = newSpeaker
	end
	Speaker.speakers[playerIndex] = newSpeaker

	return newSpeaker
end

---@private
---@return integer
function Speaker.getFreePlayerIndex()
	for i = 254, 0, -1 do
		if players[i].human == nil and not players[i].data.isSpeaker then
			return i
		end
	end
	return 0
end

---Load an audio file into the speaker.
---REQUIRES A VERY SPECIFIC AUDIO FORMAT
---Codec: pcm s16le
---Sample rate: 48000
---Channels: 1
---Pan: mono
---Bitrate: any seems to work, I use 2k
---FFMPEG command
---ffmpeg -i in.wav -b:a 2k -acodec pcm_s16le -ar 48000 -filter:a asetrate=48000, pan=mono|c0=c0 -f s16le out.pcm
---@param path string
---@return nil
function Speaker:loadAudioFile(path)
	if io.open(path, "r") == nil then
		return assert(false, "File not found")
	end
	self.encoder:open(path)
	self.currentPath = path
	self.currentDuration = 0
end

---Destroy the speaker
function Speaker:destroy()
	if self.status == Speaker.SPEAKER_STATUS.DESTROYED then
		return
	end

	print("destroying speaker")

	self.encoder:close()

	if self._baseItem.class == "Item" then
		self._baseItem:remove()
	else
		print("destroy tried to remove a", self._baseItem.class)
	end

	Speaker.speakers[self.player.index] = nil

	self.status = Speaker.SPEAKER_STATUS.DESTROYED
	self.player.data.isSpeaker = false
	self.player.data.oldVoice = nil
end

---Force the speaker into the idle state
function Speaker:idle()
	self.status = Speaker.SPEAKER_STATUS.IDLE
	self.encoder:close()
end

---pause the current audio
function Speaker:pause()
	self.status = Speaker.SPEAKER_STATUS.PAUSED
end

---play the current audio
function Speaker:play()
	self.status = Speaker.SPEAKER_STATUS.PLAYING
end

---Force the speaker into the finished state
function Speaker:finish()
	self.status = Speaker.SPEAKER_STATUS.FINISHED
	self.hasReloadedEncoder = false

	if self.meta.duration and self.meta.duration - self.currentDuration > 5 then
		error(
			"Audio file seems to be corrupted, duration is less than expected\nExpected "
				.. self.meta.duration
				.. " seconds, but got "
				.. math.round(self.currentDuration, 2)
				.. " seconds\n Path: "
				.. self.currentPath
		)

		return false
	end

	return true
end

---Set the meta data for the speaker, this is used mostly for radio stuff and debugging, not required.
---@param title string
---@param author string
---@param duration number
function Speaker:setMeta(title, author, duration)
	self.meta.title = title
	self.meta.author = author
	self.meta.duration = duration
end

---Toggle playback of the speaker
function Speaker:togglePlayback()
	if self.status == Speaker.SPEAKER_STATUS.PLAYING then
		self:pause()
	else
		self:play()
	end
end

---Get the closest speaker to a player
---@private
---@param ply Player
function Speaker.getClosestSpeaker(ply)
	local closest = nil
	local closestDist = math.huge
	if not ply.human then
		return nil
	end

	for _, speaker in pairs(Speaker.speakers) do
		local dist = speaker._baseItem.pos:dist(ply.human.pos)
		if speaker.status == speaker.SPEAKER_STATUS.PLAYING and dist < closestDist then
			closest = speaker
			closestDist = dist
		end
	end

	return closest
end

--Save player's voice table to reload
---@private
---@param player Player
---@return string[]
function Speaker.saveVoice(player)
	local ret = {}

	for i = 0, 63 do
		ret[i] = player.voice:getFrame(i)
		player.voice:setFrame(i, "", 2)
	end

	return ret
end

---Reload player's voice table
---@private
---@param player Player
---@param voice string[]
function Speaker.loadVoice(player, voice)
	for i = 0, 63 do
		player.voice:setFrame(i, voice[i], 2)
	end
end

function Speaker:__tostring()
	return "Speaker(" .. self.player.index .. ")"
end

local skipCounter = 0
hook.add("PostServerReceive", "libaudio.speaker", function()
	skipCounter = (skipCounter + 1) % 5
	if skipCounter == 0 then
		return
	end

	for _, speaker in pairs(Speaker.speakers) do
		if speaker.status == Speaker.SPEAKER_STATUS.DESTROYED ~= true and not speaker._baseItem.isActive then
			speaker:destroy()
			return
		end

		local voice = speaker.player.voice

		if speaker.status == Speaker.SPEAKER_STATUS.PAUSED then
			voice.isSilenced = false
			voice.volumeLevel = 0

			speaker.player.data.oldVoice = Speaker.saveVoice(speaker.player)
			return
		elseif speaker.status == Speaker.SPEAKER_STATUS.PLAYING then
			local frame = speaker.encoder:encodeFrame()
			if not frame then
				speaker.errorFrames = 1
			else
				speaker.errorFrames = 0
			end

			--speaker.errorFrames = 0
			speaker.currentDuration = speaker.currentDuration + 0.02
			voice.currentFrame = (voice.currentFrame + 1) % 64
			---@diagnostic disable-next-line: param-type-mismatch
			voice:setFrame(voice.currentFrame, frame, 2)
			voice.isSilenced = false
			voice.volumeLevel = 2
		elseif speaker.status == Speaker.SPEAKER_STATUS.FINISHED then
			speaker:idle()
		end
	end
end)

hook.add(
	"PostCalculateEarShots",
	"libaudio.speaker",
	---@param connection Connection
	---@param ply Player
	function(connection, ply)
		local speaker = Speaker.getClosestSpeaker(ply)
		local shot = connection:getEarShot(7)

		if speaker and speaker.status == Speaker.SPEAKER_STATUS.PLAYING then
			shot.isActive = true
			shot.player = speaker.player
			shot.human = nil
			shot.receivingItem = speaker._baseItem
			shot.distance = 1
			shot.volume = 1
		end
	end
)

hook.add("ResetGame", "Speaker", function()
	for _, speaker in pairs(Speaker.speakers) do
		speaker:destroy()
	end
end)

return Speaker
