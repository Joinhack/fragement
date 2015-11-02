#ifndef __BASE64_HEAD__
#define __BASE64_HEAD__

#include <string>


extern std::string base64_encode(unsigned char const* , unsigned int len);
extern void base64_decode(std::string const& encoded_string, unsigned char* ret, int& ret_len);
extern std::string URLDecode(const std::string &sIn);


#endif

