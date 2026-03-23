-- By @Kitokyu77
local DataStoreService = game:GetService("DataStoreService")

local DataTemplate = { -- you can put your data templates here
	Gold = 0;
	Kill = 0;
}
local DataStore = DataStoreService:GetDataStore("GlobalGameData_1") -- Change this to your DataStore name

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PcallTime = 5
local PcallDelay = 3

local SaveLoop = true
local SaveLoopTime = 45
local SaveLoopDelay = 5

local TestData = DataTemplate
local StudioDataAPI = true

local PrintDataSave = true

task.delay(3, function()
	if RunService:IsStudio() then
		local store = DataStoreService:GetDataStore("___z_")

		local success, err = pcall(function()
			store:GetAsync("Test")
		end)

		if success then
			print("["..script.Name.."]".." Can Save and Get Data. Data will save")
		else
			print("["..script.Name.."]".." Cannot Save and Get Data. Data will not save. If you want Save Data in studio, you have to go to Game Setting and turn on Studio's API use.")
			StudioDataAPI = false
		end
	else
		print("Live Server")
	end
end)

-- Module
local GlobalDataManager = {}

GlobalDataManager.Queue = {}
GlobalDataManager.DataSaving = false

local SaveLooping = task.spawn(function()
	if not SaveLoop then return end
	while true do
		local ToRemove = {}
		
		if StudioDataAPI then
			for i, v in ipairs(GlobalDataManager.Queue) do
				if not DataTemplate[v.key] then warn("NO KEY IN DataTemplate") return end
				if GlobalDataManager.DataSaving then return end
				local key = v.key
				local handler = v.handler
				local success, result
				local Count = 0

				while not success and Count < PcallTime do
					GlobalDataManager.DataSaving = true

					success, result = pcall(function()
						DataStore:UpdateAsync(key, function(oldvalue)
							oldvalue = oldvalue or DataTemplate[key]
							if PrintDataSave then print(handler(oldvalue)) end
							return handler(oldvalue)
						end)
					end)

					Count = Count + 1
				end

				if not success then
					GlobalDataManager.DataSaving = false
					warn(result)
				else
					GlobalDataManager.DataSaving = false
					table.insert(ToRemove, i)
				end

				task.wait(SaveLoopDelay)
			end
			
			for i = #ToRemove, 1, -1 do
				table.remove(GlobalDataManager.Queue, ToRemove[i])
			end
		else
			for i, v in ipairs(GlobalDataManager.Queue) do
				local key = v.key
				local handler = v.handler
				local success, result
				local Count = 0

				while not success and Count < PcallTime do
					success, result = pcall(function()
						TestData[key] = handler(TestData[key])
					end)

					Count = Count + 1
				end
				if success then
					table.insert(ToRemove, i)
				else
					warn(result)
				end
			end

			for i = #ToRemove, 1, -1 do
				table.remove(GlobalDataManager.Queue, ToRemove[i])
			end
		end

		if StudioDataAPI then
			task.wait(SaveLoopTime)
		else
			task.wait(3)
		end
	end
end)

-- 서버 닫히면 최대한 큐에 남은 거 싹쓸이 해서 저장하는 코드
game:BindToClose(function()
	task.cancel(SaveLooping)

	if StudioDataAPI then
		for i, v in ipairs(GlobalDataManager.Queue) do
			if not DataTemplate[v.key] then warn("NO KEY IN DataTemplate") return end
			if GlobalDataManager.DataSaving then return end
			local key = v.key
			local handler = v.handler
			local Count = 0

			local success, result = pcall(function()
				DataStore:UpdateAsync(key, function(oldvalue)
					oldvalue = oldvalue or DataTemplate[key]
					if PrintDataSave then print(handler(oldvalue)) end
					return handler(oldvalue)
				end)
			end)

			table.remove(GlobalDataManager.Queue, i)
			if not success then table.insert(GlobalDataManager.Queue, {Key = key, Handler = handler}) end
			task.wait(0.3)
		end
	end
end)

function GlobalDataManager:GetData(Key)
	local success, result
	local Data
	local Count = 0

	while not success and Count < PcallTime do
		if not StudioDataAPI then return DataTemplate[Key] end
		success, result = pcall(function()
			Data = DataStore:GetAsync(Key)
		end)

		Count = Count + 1
		task.wait(PcallDelay)
	end

	if success then
		return Data
	else
		return DataTemplate[Key]
	end
end

function GlobalDataManager:SaveData(Key, Handler)
	if not DataTemplate[Key] then warn("NO KEY IN DataTemplate") return end
	while GlobalDataManager.DataSaving do task.wait() end
	local success, result
	local Count = 0

	if StudioDataAPI then
		GlobalDataManager.DataSaving = true

		while not success and Count < PcallTime do
			success, result = pcall(function()
				DataStore:UpdateAsync(Key, function(oldvalue)
					oldvalue = oldvalue or DataTemplate[Key]
					if PrintDataSave then print(Handler(oldvalue)) end
					return Handler(oldvalue)
				end)
			end)

			Count = Count + 1
		end

		GlobalDataManager.DataSaving = false

		if not success then
			warn(result)
			table.insert(GlobalDataManager.Queue, {key = Key, handler = Handler})
		end
	else
		table.insert(GlobalDataManager.Queue, {key = Key, handler = Handler})
	end
end

function GlobalDataManager:UpdateData(Key, Handler)
	table.insert(GlobalDataManager.Queue, {key = Key, handler = Handler})
end

return GlobalDataManager
