int find_in_range(void* t, unsigned size, unsigned ch){
	unsigned begin_idx=0;
	unsigned end_idx=size;
	while((begin_idx < end_idx)){
		int mid=((begin_idx_idx + end_idx) / 2);
		if((t[mid].last < ch)) begin_idx = (mid + 1); else if((t[mid].first > ch)) end_idx = mid; else return (((ch - t[mid].first) % t[mid].step) == 0);
	}
	return 0;
}