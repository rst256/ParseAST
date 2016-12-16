local function switch(cases, ...)


end


local expr = switch{
	ident = {
		assign = 'print(lm(-2), lm(-1), parse_expr(lm))	lm[0]:expect";"',
		['('] = 'print(lm(-2), lm(-1), "()"',
--		ident = {
--			assign = 'print("define", lm(-3), lm(-2), lm(-1), parse_expr(lm))',
--			['('] = 'print("define", lm(-3), lm(-2), lm(-1), "()"',
--			[';']
--		}
	}

}