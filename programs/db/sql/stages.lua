return {  -- TODO hmm, really output only for the `default channel.
   init = {
      out={ output=true, ask_kind=true }
      --changable = { normal = true }, --TODO
   },
   normal = {  -- Locks off the asking of new kinds.
      out = { output=true },
   }
}
