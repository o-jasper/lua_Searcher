local This = require("Searcher.util.Class"):class_derive{ __name="Kind" }

function This:init()
   assert(self.name)

   assert(self.kinds)  -- Other kinds in existence.
   for _, el in ipairs(self) do  -- Find what is preferredly ordered as.
      if el.order_by_this then
         self.pref_order_by = el[1]
         break
      end
   end

   -- All "keyed" values may one have one entity in existence
   --  per value over the whole of the keyed values.
   self.keyed = {}
   for _, el in ipairs(self) do
      if el.keyed then
         table.insert(self.keyed, el[1])
      end
   end
end

return This
