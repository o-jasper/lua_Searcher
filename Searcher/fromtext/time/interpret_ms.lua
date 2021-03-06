local function time_interpret_ms(str, from_t)
   local i, j = string.find(str, "[%-]?[%d]+[.]?[%d]*")
   if j == 0 then --int.int or .int
      i, j = string.find(str, "[%-]?[%d]*[.]?[%d]+")
   end
   if not i or i > 2 then return nil end -- Doesnt look like a time.
   if i == 2 then -- Case of absolute times.
      if string.sub(str, 1, 1) == "a" then from_t = 0 else return nil end
   end

   -- TODO next to time-differences could also do 'day before',
   -- or time of day/year.
   local num = tonumber(string.sub(str, i or 1, j ~= 0 and j or #str))
   if j == #str then return 1000*((from_t or ms()) + 1000*num) end

   local min = 60000
   local h = 60*min
   local d = 24*h
   local f = ({ms=1, s=1000, ks=1000000, min=min, h=h, d=d, D=d,
               week=7*d, wk=7*d, w=7*d, M=31*d, Y=365.25*d})[string.sub(str, j + 1)]
   return from_t + (f or 1)*num
end

return time_interpret_ms
