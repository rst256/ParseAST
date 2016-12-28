local mtmix=require'mtmix'


local M = {}




local verb = { form={ time='past', cont=true } }
local verb_mt = mtmix.mtmix{ __index=verb }


function verb_mt.ctor(name, ...)
	local mt=mtmix.mtmix{}
	function mt:tostring()
		return ''..tostring(self.verb)..'('..tostring(self.act or '')..')'
	end
	return { mt=mt, name=name or '' }
end

function verb_mt:tostring()
	return ''..tostring(self.name)..''
end

function verb_mt:call(act, dect)
	return self.mt{ act=act, dect=dect, verb=self }
end


M.verb = verb_mt


v=verb_mt'run'
print(v, v('this'))

return M