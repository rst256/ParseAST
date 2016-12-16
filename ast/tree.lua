


local tree_mt = {
	__call = function(self, tok, ctx, ...)
		local t, node, ctx = tok, self, ctx or {}
		local t_res, n_res
		while node do

			if node.match then
				if type(node.match)=='string' then
					ctx[node.match] = t
					out(t.str)
				else
					out(node.match(t, ctx) or t.str)
				end
			end

			if node.call then
				t_res, n_res = t, node
			end

			t = t.next
			if not t then break end
--			local n
			node = node[t.lexeme]

			if type(node)=='function' then
				local n1, t1 = node(t, ctx)
				t=t1 or t
				node=n1
			end
--			node = n
		end

		if n_res then return n_res.call(t_res, ctx, tok) or false, t_res end

	end,
	__index = {},
}

function tree_mt.__add(a, b)
	return setmetatable({
		___call=function(tok, ...) return tostring(a(tok, ...) or tok.str)..tostring(b(tok, ...) or '') end
	}, tree_mt)
end

function tree_mt.__index:add_seq(seq)
	local node = self
	for k, v in ipairs(seq) do
		local n = node[tonumber(v) or v[1]]
		if not n then
			n = {}
			node[tonumber(v) or v[1]] = n
		end
		node = n
	end
	return node
end


function tree(root)
	return setmetatable(root, tree_mt)
end


function tree_mt.__index:prototype(root)
	setmetatable(root, getmetatable(self)) --fixme:
	for k,v in pairs(self) do
		if root[k]==nil then rawset(root, k ,v) end
	end
	return root
end

return tree