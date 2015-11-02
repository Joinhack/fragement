#ifndef _STOPWORD_HEAD_
#define _STOPWORD_HEAD_


#include "my_stl.h"

#ifdef _WIN32
    #include <regex>
    using std::regex;
#else
    #include <boost/regex.hpp>
    using boost::regex;
#endif


namespace mogo
{

//屏蔽词汇处理类
//满足以下三个条件之一的都算为屏蔽词
//1.单词中包含了保留字符,比如逗号,减号等系统字符
//2.包含了屏蔽字库中的某个单词
//3.匹配到了某个正则表达式
class CStopWord
{
public:
    CStopWord();
    ~CStopWord();

private:
    CStopWord(const CStopWord&);
    CStopWord& operator=(CStopWord&);

public:
    //是否屏蔽词汇
    bool IsStopWord(const char* pszWord);

public:
    //初始化保留字符集
    void InitReservedWords(const char* pszReserved);
    //增加一个屏蔽字
    void AddStopWord(const char* pszStop);
    //增加一个正则表达式
    void AddReWord(const string&);


private:
    //判断一个单词里是否包含了保留字符
    bool HasReserved(const char* pszWord);
    //判断一个单词里是否包含了某个子字符串
    bool HasSubstr(const string& strWord);
    //判断一个单词是否匹配了敏感词的正则表达式
    bool IsReMatch(const string&);

private:
    string m_strReservedWord;               //保留字符集
    list<regex*> m_reWords;               //正则表达式集合
    set<string> m_setStopWords;             //屏蔽字符集
    
};



}

#endif

