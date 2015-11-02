#ifndef __MD5_HEAD__
#define __MD5_HEAD__

#include "type_mogo.h"
#include <string>
#include <fstream>
/* Type define */
//typedef unsigned char uint8_t;
//typedef unsigned int uint32_t;
using std::string;
using std::ifstream;
/* CMd5 declaration. */
namespace mogo
{
	class CMd5 {
	public:

		CMd5();

		CMd5(const void* input, size_t length);

		CMd5(const string& str);

		CMd5(ifstream& in);

		void update(const void* input, size_t length);

		void update(const string& str);

		void update(ifstream& in);

		const uint8_t* digest();

		string toString();

		void reset();

		char* replace(char *source, char *sub, char *rep);
	private:

		void update(const uint8_t* input, size_t length);

		void final();

		void transform(const uint8_t block[64]);

		void encode(const uint32_t* input, uint8_t* output, size_t length);

		void decode(const uint8_t* input, uint32_t* output, size_t length);

		string bytesToHexString(const uint8_t* input, size_t length);

		/* class uncopyable */

		CMd5(const CMd5&);

		CMd5& operator=(const CMd5&);

	private:

		uint32_t _state[4]; /* state (ABCD) */

		uint32_t _count[2]; /* number of bits, modulo 2^64 (low-order word first) */

		uint8_t _buffer[64]; /* input buffer */

		uint8_t _digest[16]; /* message digest */
		bool _finished; /* calculate finished ? */
		static const uint8_t PADDING[64]; /* padding for calculate */
		static const char HEX[16];
		enum { BUFFER_SIZE = 1024 };
	};
}

#endif
