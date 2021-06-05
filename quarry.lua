os.loadAPI("inventory")
os.loadAPI("t")

local x = 0
local y = 0
local z = 0
local max = 16
local deep = 64
local facingfw = true

local ERROR = 0
local GO_ON  = 1
local DONE  = 2
local OUTOFFUEL = 3
local FULLINV = 4
local BLOCKEDMOV = 5


function out(s)

  s2 = s .. " @ [" .. x .. ", " .. y .. ", " .. z .. "]"
      
  print(s2)
  rednet.broadcast(s2, "miningTurtle")
  
end

function dropInChest()

  turtle.turnLeft()
  
  local success, data = turtle.inspect()
  
  if success then
    if data.name == "minecraft:chest" then
    
      out("Dropping items in chest")
      
      for i=1, 16 do
        turtle.select(i)
        
        data = turtle.getItemDetail()
        
        if data ~= nil and (data.damage == nil or
            data.name .. data.damage ~= "minecraft:coal1") then
        
          turtle.drop()
        end
      end
    end
  end
  
  turtle.turnRight()
  
end

function goDown()

  while true do
  
    if turtle.getFuelLevel() <= fuelNeededToGoBack() then
      if not refuel() then
        return OUTOFFUEL
      end
    end
  
    if not turtle.down() then

      turtle.up()
      z = z+1

      return
    end
      
    z = z-1
      
  end
end

function fuelNeededToGoBack()

  return -z + x + y + 2
end

function refuel()

  for i=1, 16 do
    
    -- Only run on Charcoal
    
    turtle.select(i)
    
    item = turtle.getItemDetail()
    
    -- if item then print(item.name) end
    
    if item and
        item.name == "minecraft:coal" and
        item.damage == 1 and
        turtle.refuel(1) then
        
      return true
    end
  end
  
  return false
end

function moveH()

  if inventory.isInventoryFull() then
    
    out("Dropping thrash")
    inventory.dropThrash()
    
    if inventory.isInventoryFull() then
      out ("Stacking items")
      inventory.stackItems()
    end
    
    if inventory.isInventoryFull() then
      out("Full inventory!")
      return FULLINV  
    end
  end
  
  if turtle.getFuelLevel() <= fuelNeededToGoBack() then
    if not refuel() then
      out("Out of fuel!")
      return OUTOFFUEL
    end
  end
  
  if facingfw and y<max-1 then
  -- Going one way
    t.dig()
    t.digUp()
    t.digDown()
  
    if t.fw() == false then
      return BLOCKEDMOV
    end
    
    y = y+1
  
  elseif not facingfw and y>0 then
  -- Going the other way
    t.dig()
    t.digUp()
    t.digDown()
    
    if t.fw() == false then
      return BLOCKEDMOV
    end
    
    y = y-1
    
  else
    
    if x+1 >= max then
      t.digUp()
      t.digDown()
      return DONE -- Done with this Y level
    end
    
    -- If not done, turn around
    if facingfw then
      turtle.turnRight()
    else
      turtle.turnLeft()
    end
    
    t.dig()
    t.digUp()
    t.digDown()
    
    if t.fw() == false then
      return BLOCKEDMOV
    end
    
    x = x+1
    
    if facingfw then
      turtle.turnRight()
    else
      turtle.turnLeft()
    end
    
    facingfw = not facingfw
    
  end
  
  return GO_ON
  
end

function doSquare()
  
  local report = GO_ON

  while report == GO_ON do
    report = moveH()
  end
  
  if report == DONE then
    return GO_ON
  end
  
  return report  
end

function goToOrigin()
  
  if facingfw then
    
    turtle.turnLeft()
    
    t.fw(x)
    
    turtle.turnLeft()
    
    t.fw(y)
    
    turtle.turnRight()
    turtle.turnRight()
    
  else
    
    turtle.turnRight()
    
    t.fw(x)
    
    turtle.turnLeft()
    
    t.fw(y)
    
    turtle.turnRight()
    turtle.turnRight()
    
  end
  
  x = 0
  y = 0
  facingfw = true
  
end

function goUp()

  while z < 0 do
    
    t.up()
    
    z = z+1
    
  end
  
  goToOrigin()
  
end

function mainloop()

  while true do

    local report = doSquare()
  
    if report ~= GO_ON then
      goUp()
      return report
    end
    
    goToOrigin()
    
    for i=1, 3 do
      t.digDown()
      success = t.down()
    
      if not success then
        goUp()
        return BLOCKEDMOV
      end

      z = z-1
      out("Z: " .. z)

    end
  end
end

rednet.open("right")

out("\n\n\n-- WELCOME TO THE MINING TURTLE --\n\n")

while true do

  goDown()

  local report = mainloop()
  dropInChest()
  
  if report ~= FULLINV then
    break
  end
end

rednet.close("right")