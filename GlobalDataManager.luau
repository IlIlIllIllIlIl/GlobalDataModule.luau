-- By @Kitokyu77
local DataStoreService = game:GetService("DataStoreService")

local DataTemplete = { -- you can put your data templates here
	DonateBoard = {
		One = {Player = "N", Robux = 0, UserId = 0};
		Two = {Player = "N", Robux = 0, UserId = 0};
		Three = {Player = "N", Robux = 0, UserId = 0};
		Four = {Player = "N", Robux = 0, UserId = 0};
		Five = {Player = "N", Robux = 0, UserId = 0};
	}
	
	
}
local DataStore = DataStoreService:GetDataStore("GlobalGameData_1") -- Change this to your DataStore name

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PcallTime = 5
local PcallDelay = 3

local SaveLoop = true
local SaveLoopTime = 5
local SaveLoopDelay = 3

local TestData = DataTemplete -- 이건 스튜디오에서 데이터스토어 API 활성화 안 했을때 쓰는거임
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

--[[task.delay(3, function()
	if RunService:IsStudio() then
		local store = DataStoreService:GetDataStore("TestAPI")

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
end)]]

GlobalDataManager.Queue = {}
GlobalDataManager.DataSaving = false

-- 저장 실패한 거 다시 시도하는 것 아니면 업데이트 데이터로 해둔 것
local SaveLooping = task.spawn(function()
	if not SaveLoop then return end -- SaveLoop true로 안해두면 자동저장 없음 ㅅㄱ
	while true do
		if StudioDataAPI then
			for i, v in pairs(GlobalDataManager.Queue) do
				if not DataTemplete[v.key] then warn("NO KEY IN DATATEMPLETE") return end
				if GlobalDataManager.DataSaving then return end
				local key = v.key
				local handler = v.handler
				local success, result
				local Count = 0
				
				while not success and Count < PcallTime do
					GlobalDataManager.DataSaving = true
					
					success, result = pcall(function()
						DataStore:UpdateAsync(key, function(oldvalue)
							oldvalue = oldvalue or DataTemplete[key]
							if PrintDataSave then print(handler(oldvalue)) end
							return handler(oldvalue)
						end)
					end)
					
					Count = Count + 1
				end
				
				if not success then
					GlobalDataManager.DataSaving = false
					warn(result)
					--table.insert(GlobalDataManager.Queue, {key = key, handler = handler})
				else
					GlobalDataManager.DataSaving = false
					table.remove(GlobalDataManager.Queue, i)
				end
				
				task.wait(SaveLoopDelay)
			end
		else
			for i, v in pairs(GlobalDataManager.Queue) do
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
					table.remove(GlobalDataManager.Queue, i)
				else
					warn(result)
				end
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
		for i, v in pairs(GlobalDataManager.Queue) do
			if not DataTemplete[v.key] then warn("NO KEY IN DATATEMPLETE") return end
			if GlobalDataManager.DataSaving then return end
			local key = v.key
			local handler = v.handler
			local Count = 0
			
			local success, result = pcall(function()
				DataStore:UpdateAsync(key, function(oldvalue)
					oldvalue = oldvalue or DataTemplete[key]
					if PrintDataSave then print(handler(oldvalue)) end
					return handler(oldvalue)
				end)
			end)
			
			table.remove(GlobalDataManager.Queue, i)
			if not success then table.insert(GlobalDataManager.Queue, {Key = key, Handler = handler}) end
			task.wait(0.3)
		end
	--[[else
		for i, v in pairs(GlobalDataManager.Queue) do
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
				table.remove(GlobalDataManager.Queue, i)
			else
				warn(result)
			end
		end

		if StudioDataAPI then
			task.wait(SaveLoopTime)
		else
			task.wait(3)
		end]]
	end
end)

-- 데이터를 불러오고 불러오기 실패 시 템플릿 데이터에서 가져옴 Key에 string 값 넣어줘야함
function GlobalDataManager:GetData(Key)
	local success, result
	local Data
	local Count = 0
	
	while not success and Count < PcallTime do
		if not StudioDataAPI then return DataTemplete[Key] end
		success, result = pcall(function()
			Data = DataStore:GetAsync(Key)
		end)
		
		Count = Count + 1
		task.wait(PcallDelay)
	end
	
	if success then
		return Data
	else
		return DataTemplete[Key]
	end
end

-- 바로바로 저장해야 하는 것 Key에는 string값만 넣으세요 (예시 : 코인, 무기 등)
function GlobalDataManager:SaveData(Key, Handler)
	if not DataTemplete[Key] then warn("NO KEY IN DATATEMPLETE") return end
	while GlobalDataManager.DataSaving do task.wait() end
	local success, result
	local Count = 0
	
	if StudioDataAPI then
		GlobalDataManager.DataSaving = true

		while not success and Count < PcallTime do
			success, result = pcall(function()
				DataStore:UpdateAsync(Key, function(oldvalue)
					oldvalue = oldvalue or DataTemplete[Key]
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

-- 현재 세션에만 저장되며 중요한 저장은 SaveData 필수 Key에는 string값만 넣으세요
function GlobalDataManager:UpdateData(Key, Handler)
	table.insert(GlobalDataManager.Queue, {key = Key, handler = Handler})
end

return GlobalDataManager
