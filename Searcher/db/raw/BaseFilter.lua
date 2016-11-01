
-- Basic information about a filter to derive from.

local This = require("Searcher.util.Class"):class_derive{ __name="Base Filter" }

function This:figure_order_by(kind)
   return (self.order_by ~= "default" and self.order_by) or
      kind.pref_order_by or "false"
end

function This:figure_limit_cnt(kind)
   return self.limit_cnt or kind.pref_limit_cnt or -1
end

return This
