local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")

local player = players.LocalPlayer
local viewModels = workspace:WaitForChild("ViewModels")
local camera = workspace.CurrentCamera

local guns = replicatedStorage:WaitForChild("Guns")

local gunConnection = nil
local isAiming = false

local module = {}

local function PositionViewModel(gun: Model, config)
	local gunOffset = config.Offset
	local lastCameraCFrame = camera.CFrame
	local targetCFrame = CFrame.new()
	local swayOffset = CFrame.new()
	local swaySize = 1
	local isWalking = false
	
	gunConnection = runService.RenderStepped:Connect(function(deltaTime)
		local character = player.Character or player.CharacterAdded:Wait()
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				--local gunOffset = CFrame.new(workspace.OffsetX.value, workspace.OffsetY.Value, workspace.OffsetZ.Value)
				if humanoid.MoveDirection.Magnitude > 0 then
					isWalking = true
				else
					isWalking = false
				end
				
				local aimOffset = gun.Aim.CFrame:Inverse() * camera.CFrame * CFrame.new(0, gunOffset.Y, gunOffset.Z)
				local walkSineWave = math.sin(time() * 2*4) / 25
				local walkCosWave = math.cos(time() * 3*4) / 20
				local walkSineRotation = math.sin(time() * 2*4) / 25
				local walkCosRotation = math.cos(time() * 3*4) / 20
				
				local X, Y, Z = (camera.CFrame:ToObjectSpace(lastCameraCFrame)):ToOrientation()
				swayOffset = swayOffset:Lerp(CFrame.Angles(math.sin(X/2) * swaySize, math.sin(Y / 2) * swaySize, 0), 0.1)
				
				local walkCFrameOffset = CFrame.new(walkSineWave, walkCosWave, 0) * CFrame.fromEulerAnglesXYZ(0, 0, walkSineRotation)
				
				if isAiming then
					walkCFrameOffset = CFrame.new(walkSineWave/10, walkCosWave/10, 0)
				end
				
				if isWalking and not isAiming then
					targetCFrame = targetCFrame:Lerp(gunOffset * walkCFrameOffset * swayOffset, 0.1)
				elseif not isWalking and not isAiming then
					targetCFrame = targetCFrame:Lerp(gunOffset * swayOffset, 0.1)
				end
				
				if isWalking and isAiming then
					targetCFrame = targetCFrame:Lerp(walkCFrameOffset * swayOffset * aimOffset, 0.1)
				elseif not isWalking and isAiming then
					targetCFrame = targetCFrame:Lerp(swayOffset * aimOffset, 0.1)
					
				end
				
				lastCameraCFrame = camera.CFrame
				
				gun:PivotTo(camera.CFrame * targetCFrame)
				
				
				print(isWalking)
			end
		end
	end)
end

function module.EquipGun(gunName: string)
	local foundGun = guns:FindFirstChild(gunName)
	
	if foundGun == nil then
		return
	end
	
	local gun = foundGun:Clone()
	gun.Parent = viewModels
	
	PositionViewModel(gun, require(foundGun.Config))
end

userInputService.InputBegan:Connect(function(input, gameProcessedEvent) 
	if gameProcessedEvent then
		return
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = true
	end
end)

userInputService.InputEnded:Connect(function(input, gameProcessedEvent) 
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
	end
end)

return module
