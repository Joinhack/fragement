
static const char p[] = {0x4,0x3,0x2,0x1};

void kstart() {
	int c = sizeof(p)/sizeof(char);
	int t = 0;
	int i = 0;
	for(i = 0; i < c; i++) {
		t += p[i];
	}
	while(1);
}
