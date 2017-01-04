function find_in_range(t<-range_table, size<-unsigned, ch<-unsigned)<-int
  local begin_idx = 0
  local end_idx
  while (begin_idx < end_idx) do
	  local mid<-int = ((begin_idx_idx + end_idx) / 2)
	  if (t < ch) then
			begin_idx = (mid + 1)
		else
			if (t[mid].first > ch) then
				end_idx = mid
			else
			  res = ((ch - t[mid].first) % t[mid].step)
			  return (res == 0)
			end
		end
	end
  if (begin_idx == 0) then
	  print('begin_idx == 0')
	  return 0
	end
  return (~mid ~= 0)
end