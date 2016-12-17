const int[4] matchers;
int anon_pattern_fn2(const char* src){
	char ch=getch(src);
	int matched;
	const char* old_ctx=*(src);
	match_single((2 == ch));
	match_single((8 == ch));
	return 0;
}