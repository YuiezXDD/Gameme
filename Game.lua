--// SERVICES
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// PLAYER
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// QUEST POINTS
local PointA = Vector3.new(63, 254, -664)
local PointB = Vector3.new(66, 254, -666)

--// CONFIG
local ACCEPT_DISTANCE = 5
local ITEM_NAME = "Apple"
local COOLDOWN = 30

--// STATE
local AUTO_ENABLED = false
local IS_RUNNING = false
local CAMERA_LOCKED = false

--// CHARACTER HANDLER
local character, humanoid, hrp

local function bindCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	hrp = char:WaitForChild("HumanoidRootPart")

	humanoid.Died:Connect(function()
		AUTO_ENABLED = false
		IS_RUNNING = false
		unlockCamera()
	end)
end

bindCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(bindCharacter)

--// CAMERA LOCK
function lockCamera()
	if CAMERA_LOCKED then return end
	CAMERA_LOCKED = true
	camera.CameraType = Enum.CameraType.Scriptable
	local cf = camera.CFrame
	RunService:BindToRenderStep("LockCam", 201, function()
		camera.CFrame = cf
	end)
end

function unlockCamera()
	if not CAMERA_LOCKED then return end
	CAMERA_LOCKED = false
	RunService:UnbindFromRenderStep("LockCam")
	camera.CameraType = Enum.CameraType.Custom
end

--// INPUT
local function pressE()
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(0.05)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function holdE(sec)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(sec)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

--// UTILS
local function moveTo(pos)
	humanoid:MoveTo(pos)
	repeat
		RunService.Heartbeat:Wait()
	until (hrp.Position - pos).Magnitude <= ACCEPT_DISTANCE or not AUTO_ENABLED
	humanoid:Move(Vector3.zero, false)
end

local function hasItem(name)
	return player.Backpack:FindFirstChild(name)
		or character:FindFirstChild(name)
end

--// MAIN LOOP
task.spawn(function()
	while true do
		if AUTO_ENABLED and not IS_RUNNING then
			IS_RUNNING = true
			lockCamera()

			-- A : GET ITEM
			moveTo(PointA)
			pressE()
			while AUTO_ENABLED and not hasItem(ITEM_NAME) do
				task.wait(0.2)
				pressE()
			end
			if not AUTO_ENABLED then
				IS_RUNNING = false
				unlockCamera()
				continue
			end

			task.wait(1)

			-- B : SUBMIT QUEST (เวอร์ชันสมบูรณ์)
			while AUTO_ENABLED and hasItem(ITEM_NAME) do
				moveTo(PointB)
				task.wait(0.2)

				pressE()
				task.wait(0.3)

				holdE(3)
				task.wait(0.3)
			end

			-- ถ้าถูกปิดหรือตาย → หยุดทันที ไม่ยิง Finish
			if not AUTO_ENABLED then
				IS_RUNNING = false
				unlockCamera()
				continue
			end

			-- รอ 1 วิ ก่อนจบเควช
			task.wait(1)

			-- FINISH (ยิงเฉพาะตอนยังเปิดระบบอยู่)
			if AUTO_ENABLED then
				ReplicatedStorage:WaitForChild("Remote")
					:WaitForChild("FruitMinigameEvent")
					:FireServer("Finish")
			end

			-- COOLDOWN
			for i = COOLDOWN, 1, -1 do
				if not AUTO_ENABLED then break end
				task.wait(1)
			end

			unlockCamera()
			IS_RUNNING = false
		end
		task.wait(0.2)
	end
end)

--// GUI TOGGLE
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton", gui)
btn.Size = UDim2.fromOffset(50, 50)
btn.Position = UDim2.fromScale(0.9, 0.5)
btn.Text = ""
btn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
btn.AutoButtonColor = false
btn.AnchorPoint = Vector2.new(0.5, 0.5)

local corner = Instance.new("UICorner", btn)
corner.CornerRadius = UDim.new(1, 0)

btn.MouseButton1Click:Connect(function()
	AUTO_ENABLED = not AUTO_ENABLED
	btn.BackgroundColor3 = AUTO_ENABLED
		and Color3.fromRGB(0, 200, 0)
		or Color3.fromRGB(200, 0, 0)

	if not AUTO_ENABLED then
		unlockCamera()
	end
end)
