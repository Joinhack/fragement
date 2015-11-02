#include "logger.h"
#include "md5.h"
#include <stdio.h> 
#include <string.h> 
#include <vector>
#include <map>
#include <curl/curl.h> 
#include "other_def.h"
#include <iconv.h>
#include "threadpool.h"

using namespace std;
using namespace mogo;


#define MAX_BUF 	 65536 

char wr_buf[MAX_BUF + 1];
int  wr_index;


/* 
* Write data callback function (called within the context of 
* curl_easy_perform. 
*/ 
size_t write_data( void *buffer, size_t size, size_t nmemb, void *userp ) 
{ 
	int segsize = size * nmemb; 

	/* Check to see if this data exceeds the size of our buffer. If so, 
	* set the user-defined context value and return 0 to indicate a 
	* problem to curl. 
	*/ 
	if ( wr_index + segsize > MAX_BUF ) { 
		*(int *)userp = 1; 
		return 0; 
	} 

	/* Copy the data from the curl buffer into our buffer */ 
	memcpy( (void *)&wr_buf[wr_index], buffer, (size_t)segsize ); 

	LogDebug("write_data","return buffer = %s\n", buffer);

	/* Update the write index */ 
	wr_index += segsize; 

	/* Null terminate the buffer */ 
	wr_buf[wr_index] = 0; 

	/* Return the number of bytes received, indicating to curl that all is okay */ 
	return segsize; 
} 


size_t write_string( void *buffer, size_t size, size_t nmemb, void *userp )
{
	int segsize = size * nmemb;
	*(string*) userp += string((char*) buffer);
	return segsize;
}



void set_share_handle(CURL* curl_handle)
{
	static CURLSH* share_handle = NULL;
	if (!share_handle)
	{
		share_handle = curl_share_init();
		curl_share_setopt(share_handle, CURLSHOPT_SHARE, CURL_LOCK_DATA_DNS);
	}
	curl_easy_setopt(curl_handle, CURLOPT_SHARE, share_handle);
	curl_easy_setopt(curl_handle, CURLOPT_DNS_CACHE_TIMEOUT, 60 * 5);
	//curl_easy_setopt(curl_handle, CURLOPT_DNS_CACHE_TIMEOUT, 0);
}



int GetUrl_new(const char* url, OUT string& result)
{
	CURL *curl;
	CURLcode ret;
	string tmp;
	curl_global_init(CURL_GLOBAL_ALL);
	curl = curl_easy_init();
	set_share_handle(curl);

	if (!curl)
	{
		//LogError("reqUrl","couldn't init curl\n"); 
		return -1;
	}

	/* Tell curl the URL of the file we're going to retrieve */
	curl_easy_setopt(curl, CURLOPT_URL, url);
	//curl_easy_setopt(curl, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);

	/* Tell curl that we'll receive data to the function write_data, and 
	* also provide it with a context pointer for our error return. 
	*/
	// curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *) &tmp);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_string);
	//curl_easy_setopt( curl, CURLOPT_TIMEOUT, 10 );
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
	curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L); //多线程必须屏蔽该信号
	curl_easy_setopt(curl, CURLOPT_DNS_USE_GLOBAL_CACHE, 1);
	//curl_easy_setopt(curl, CURLOPT_RESOLVE, host);


	/* Allow curl to perform the action */
	ret = curl_easy_perform(curl);

	/* Emit the page if curl indicates that no errors occurred */
	if (ret == 0) result = tmp;
	else
	{
		char a[16] ={0};
		sprintf(a, "error: %d\n", ret);
		LogDebug( "GetUrl_new", "%s\n", a );
		result = a;
	}

	curl_easy_cleanup(curl);

	return ret;
}


int GetUrl(const char* url, OUT string& result)
{
	return GetUrl_new(url, result);

}
/* 
* Simple curl application to read the index.html file from a Web site. 
*/
int reqUrl(const char* url)
{
	string result;
	return GetUrl_new(url, result);

}



//url  :"http://postit.example.com/moo.cgi");
//params: name=daniel&project=curl

int http_post(const char* url,const char*  params, OUT string& result)
{
	CURL *curl;
	CURLcode ret;
	string tmp;

	/* In windows, this will init the winsock stuff */ 
	curl_global_init(CURL_GLOBAL_ALL);

	/* get a curl handle */ 
	curl = curl_easy_init();
	if(curl) {

		/* First set the URL that is about to receive our POST. This URL can
		just as well be a https:// URL if that is what should receive the
		data. */ 
		curl_easy_setopt(curl, CURLOPT_URL, url);
		/* Now specify the POST data */ 
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, params);

		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *) &tmp);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_string);

		/* Perform the request, res will get the return code */ 
		ret = curl_easy_perform(curl);

		/* Check for errors */ 

		if (ret == CURLE_OK) result = tmp;
		else
		{
			char a[16] ={0};
			sprintf(a, "error: %d\n", ret);
			LogDebug( "GetUrl_new", "%s\n", a );
			result = a;
		}

		/* always cleanup */ 
		curl_easy_cleanup(curl);
	}
	curl_global_cleanup();
	return 0;

}




