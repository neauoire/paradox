local Instructor = { dict = {} }

-- Utils

local char_at = function(str,index,length)
  length = (length or 1)
  return string.sub(str,index,index+length-1)
end

local num_to_bin = function(num)
  local t = {}
  for b=8,1,-1 do
    rest = math.fmod(num,2)
    t[b] = math.floor(rest)
    num = (num-rest)/2
  end
  return table.concat(t)
end

local num_to_oct = function(num)
  return ((num-1)%8)+1
end

local num_to_note = function(num)
  notes = { 'C','c','D','d','E','F','f','G','g','A','a','B' }
  return notes[((num-1) % 12)+1]
end

-- Begin

Instructor.init = function(self)
  print('Instructor','Init')
  self:build()
end

Instructor.bind = function(self,program)
  self.program = program
end

-- IF

Instructor.make_if_type = function(self,id,bin)
  if char_at(bin,5,2) == '11' then return 'BANG'
  elseif char_at(bin,5) == '1' then return 'STEP'
  elseif char_at(bin,6) == '1' then return 'OCT'
  else return 'NOTE' end
end

Instructor.build_if = function(self,id,bin)
  local _type = self:make_if_type(id,bin)
  local _value = self:make_number(id,bin)
  if _type == 'NOTE' then
    _value = num_to_note(_value)
  end

  if _type and _value then
    self.dict[id] = { cmd = 'IF', key = _type, val = _value, name = 'IF '.._type..'='.._value }
  else
    print('Incomplete IF instruction: '..bin, _type,_value)
  end
end

-- SET

Instructor.make_set_type = function(self,id,bin)
  if char_at(bin,5,2) == '11' then return 'RATE'
  elseif char_at(bin,5) == '1' then return 'VEL'
  elseif char_at(bin,6) == '1' then return 'OCT'
  else return 'NOTE' end
end

Instructor.build_set = function(self,id,bin)
  local _type = self:make_set_type(id,bin)
  local _value = self:make_number(id,bin)
  if _type == 'NOTE' then
    _value = num_to_note(_value)
  elseif _type == 'OCT' then
    _value = num_to_oct(_value)
  end
  
  if _type and _value then
    self.dict[id] = { cmd = 'SET', key = _type, val = _value, name = 'SET '.._type..'='.._value }
  else
    print('Incomplete SET instruction: '..bin)
  end
end

-- SEND

Instructor.make_send_type = function(self,id,bin)
  if char_at(bin,5,2) == '11' then return 'SYS'
  elseif char_at(bin,5) == '1' then return 'BANG'
  elseif char_at(bin,6) == '1' then return 'OSC'
  else return 'CHAN' end
end

Instructor.build_send = function(self,id,bin)
  local _type = self:make_send_type(id,bin)
  local _value = self:make_number(id,bin)
  
  if _type and _value then
    self.dict[id] = { cmd = 'SEND', key = _type, val = _value, name = 'SEND '.._type..'>'.._value }
  else
    print('Incomplete SEND instruction: '..bin)
  end
end

-- WHEN

Instructor.make_do_type = function(self,id,bin)
  if char_at(bin,5,2) == '11' then return 'CLAMP'
  elseif char_at(bin,5) == '1' then return 'INCR'
  elseif char_at(bin,6) == '1' then return 'DECR'
  else return 'LIMIT' end
end

Instructor.build_do = function(self,id,bin)
  local _type = self:make_do_type(id,bin)
  local _value = self:make_number(id,bin)
  if _type == 'NOTE' then 
    _value = num_to_note(_value)
  end

  if _type and _value then
    self.dict[id] = { cmd = 'DO', key = _type, val = _value, name = 'DO '.._type..':'.._value }
  else
    print('Incomplete DO instruction: '..bin)
  end
end

-- Generics

Instructor.make_octave = function(self,id,bin)
  local key = self:make_number(id,bin)
  if key == 10 then return 'INC' end
  if key ==  9 then return 'DEC' end
  return math.floor(((key-1) % 8)+1)
end

Instructor.make_number = function(self,id,bin)
  if char_at(bin,1,4) == '0000' then return 1 end
  if char_at(bin,1,4) == '0001' then return 2 end
  if char_at(bin,1,4) == '0010' then return 3 end
  if char_at(bin,1,4) == '0011' then return 4 end
  if char_at(bin,1,4) == '0100' then return 5 end
  if char_at(bin,1,4) == '0101' then return 6 end
  if char_at(bin,1,4) == '0110' then return 7 end
  if char_at(bin,1,4) == '0111' then return 8 end
  if char_at(bin,1,4) == '1000' then return 9 end
  if char_at(bin,1,4) == '1001' then return 10 end
  if char_at(bin,1,4) == '1010' then return 11 end
  if char_at(bin,1,4) == '1011' then return 12 end
  if char_at(bin,1,4) == '1100' then return 13 end
  if char_at(bin,1,4) == '1101' then return 14 end
  if char_at(bin,1,4) == '1110' then return 15 end
  if char_at(bin,1,4) == '1111' then return 16 end
  return '0'
end

Instructor.build = function(self)
  print('Instruct','Building..')
  for id=1,255 do
    local bin = num_to_bin(id)
    if string.sub(bin,7,8) == '11' then
      self:build_if(id,bin)
    elseif string.sub(bin,7,8) == '10' then
      self:build_send(id,bin)
    elseif string.sub(bin,7,8) == '01' then
      self:build_set(id,bin)
    else
      self:build_do(id,bin)
    end
  end
  print('Instruct','Completed.')
end

-- Utils

Instructor.get = function(self,id)
  return self.dict[id]
end

Instructor.name = function(self,instruction)
  if instruction == nil then return 'ERROR' end
  if instruction.cmd == nil then return 'ERROR:CMD' end
  if instruction.key == nil then return 'ERROR:KEY' end
  if instruction.val == nil then return 'ERROR:VAL' end
  return instruction.cmd..instruction.key..instruction.val
end

Instructor.get_name = function(self,num)
  if self.dict[num] then
    return self.dict[num].name
  end
  return '--'
end

return Instructor