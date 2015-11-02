#include "stopword.h"
#include "logger.h"
#include "util.h"

#ifdef _WIN32
using namespace std;
#else
using namespace boost;
#endif // _WIN32

namespace mogo
{

CStopWord::CStopWord()
{

}

CStopWord::~CStopWord()
{
    ClearContainer(m_reWords);
}

//初始化保留字符集
void CStopWord::InitReservedWords(const char* pszReserved)
{
    m_strReservedWord.assign(pszReserved);
}

//增加一个屏蔽字
void CStopWord::AddStopWord(const char* pszStop)
{
    m_setStopWords.insert(pszStop);
}

//增加一个正则表达式
void CStopWord::AddReWord(const string& strWord1)
{
    string strWord(strWord1);
    Trim(strWord);
    regex_constants::syntax_option_type fl = regex_constants::icase;  
    regex* reg = new regex(strWord, fl);  
    m_reWords.push_back(reg);
}

//判断一个单词里是否包含了保留字符
bool CStopWord::HasReserved(const char* pszWord)
{
    return strpbrk(pszWord, m_strReservedWord.c_str()) != NULL;
}

//判断一个单词里是否包含了某个子字符串
bool CStopWord::HasSubstr(const string& strWord)
{
    set<string>::const_iterator iter1 = m_setStopWords.begin();
    for(; iter1 != m_setStopWords.end(); ++iter1)
    {
        if(strWord.find(*iter1) != string::npos)
        {
            return true;
        }
    }

    return false;
}

//判断一个单词是否匹配了敏感词的正则表达式
bool CStopWord::IsReMatch(const string& strWord)
{
    list<regex*>::iterator iter1 = m_reWords.begin();    
    for(; iter1 != m_reWords.end(); ++iter1)
    {
        if(regex_match(strWord, **iter1))
        {
            return true;
        }
    }    

    return false;
}

//是否屏蔽词汇
bool CStopWord::IsStopWord(const char* pszWord)
{
    return HasReserved(pszWord) || HasSubstr(pszWord) || IsReMatch(pszWord);
}


}


