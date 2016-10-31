--  Copyright (C) 26-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- Kinds are seen as "data-like" objects, some elements are computed.

local function figure_args_n_sets(self)
   self.args, self.sets = {}, {}

   for i = 1,#self do  -- Find what is preferredly ordered as.
      local el = rawget(self,i)
      local name = el[1]
      assert(name)
      self.args[name] = el

      if el.order_by_this then
         assert(not self.pref_order_by, "Can only preferentially order by one thing.")
         self.pref_order_by = name
      end
      self.sets[name] = el[3]  -- What other kind it refers to.
   end
end

local function figure_keyeds(self)
   self.keyed = {}
   local main_key
   for i = 1,#self do
      local el = rawget(self, i)
      if el.keyed then
         if el.main_key then
            assert(not main_key, "May only have one main key.")
            main_key = el.main_key
         end
         table.insert(self.keyed, el[1])
      end
   end
   self.main_key = main_key or (self[1] or {}).main_key
end

local kindfuns = {
   args = figure_args_n_sets, sets = figure_args_n_sets,
   -- All "keyed" values may one have one entity in existence
   --  per value over the whole of the keyed values.
   keyed = figure_keyeds, main_key = figure_keyeds,
}
local KindMeta = {
   __index = function(self, key)
      local fun =  kindfuns[key]
      if fun then
         fun(self)
      end
      return rawget(self, key)
   end
}
--function KindMeta.new_1(new)  -- TODO use this instead of raw right now.
--   return setmetatable(new, KindMeta)
--end
return KindMeta
