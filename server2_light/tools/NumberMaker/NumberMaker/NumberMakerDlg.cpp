
// NumberMakerDlg.cpp : implementation file
//

#include "stdafx.h"
#include "NumberMaker.h"
#include "NumberMakerDlg.h"
#include "afxdialogex.h"

#include <sstream>
#include <algorithm>
#include "md5.h"
using namespace std;

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// CAboutDlg dialog used for App About

class CAboutDlg : public CDialogEx
{
public:
	CAboutDlg();

// Dialog Data
	enum { IDD = IDD_ABOUTBOX };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

// Implementation
protected:
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialogEx(CAboutDlg::IDD)
{
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialogEx)
END_MESSAGE_MAP()


// CNumberMakerDlg dialog




CNumberMakerDlg::CNumberMakerDlg(CWnd* pParent /*=NULL*/)
	: CDialogEx(CNumberMakerDlg::IDD, pParent)
	, m_nType(0)
	, m_nCount(0)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CNumberMakerDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_EDIT1, m_szItemId);
	DDX_Control(pDX, IDC_EDIT2, m_szCount);
	DDX_Control(pDX, IDC_EDIT3, m_Type);
}

BEGIN_MESSAGE_MAP(CNumberMakerDlg, CDialogEx)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_EN_CHANGE(IDC_EDIT3, &CNumberMakerDlg::OnEnChangeEdit3)
	ON_BN_CLICKED(IDC_BUTTON1, &CNumberMakerDlg::OnBnClickedButton1)
END_MESSAGE_MAP()


// CNumberMakerDlg message handlers

BOOL CNumberMakerDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	// Add "About..." menu item to system menu.

	// IDM_ABOUTBOX must be in the system command range.
	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != NULL)
	{
		BOOL bNameValid;
		CString strAboutMenu;
		bNameValid = strAboutMenu.LoadString(IDS_ABOUTBOX);
		ASSERT(bNameValid);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// Set the icon for this dialog.  The framework does this automatically
	//  when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon

	// TODO: Add extra initialization here

	return TRUE;  // return TRUE  unless you set the focus to a control
}

void CNumberMakerDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialogEx::OnSysCommand(nID, lParam);
	}
}

// If you add a minimize button to your dialog, you will need the code below
//  to draw the icon.  For MFC applications using the document/view model,
//  this is automatically done for you by the framework.

void CNumberMakerDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this); // device context for painting

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// Center icon in client rectangle
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// Draw the icon
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialogEx::OnPaint();
	}
}

// The system calls this function to obtain the cursor to display while the user drags
//  the minimized window.
HCURSOR CNumberMakerDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}



void CNumberMakerDlg::OnEnChangeEdit3()
{
	// TODO:  If this is a RICHEDIT control, the control will not
	// send this notification unless you override the CDialogEx::OnInitDialog()
	// function and call CRichEditCtrl().SetEventMask()
	// with the ENM_CHANGE flag ORed into the mask.

	// TODO:  Add your control notification handler code here
}


void CNumberMakerDlg::OnBnClickedButton1()
{
	CString str_item_id,strType, strCount;
	m_szItemId.GetWindowText(str_item_id);
	m_Type.GetWindowText(strType);
	m_szCount.GetWindowText(strCount);


	if (strType == _T(""))
	{
		MessageBox(_T("请输入组号"));
		return;
	}

	if (str_item_id == _T(""))
	{
		MessageBox(_T("请输入玩家得到的道具id"));
		return;
	}
	if (strCount == _T(""))
	{
		MessageBox(_T("请输入生成激活码的个数"));
		return;
	}

	CString strSave = SaveAs();

	if(strSave == "")
	{
		return;
	}

	CString strSave_sql = strSave + _T(".sql");

	int count = _ttoi(strCount.GetString());

	struct tm *t;
	time_t tt;
	time(&tt);
	t=localtime(&tt);


	char time_buffer[64]={0};	
	sprintf(time_buffer, "%04d-%02d-%02d %02d:%02d:%02d",t->tm_year+1900,t->tm_mon+1,t->tm_mday,t->tm_hour,t->tm_min,t->tm_sec);


	string strAll_sql;
	string keys; //生成的结果

	MD5 md5;
	::srand((unsigned)time(NULL));  

	for(int i = 0; i < count; ++i)
	{
		stringstream ss_premd5;
		stringstream ss_tab;
		int nRand =  ::rand();
		//生成规则 = md5( ahzs + 卡类型 + 生成日期 + 随机数 + 序号)之类的
		ss_premd5 << str_item_id.GetString() << strType.GetString()<< time_buffer <<nRand  << i;
		//ss_tab << strServer.GetString() << "\t" << strType.GetString() << "\t" << time_buffer << "\t"  << nRand << "\t" << i <<"\t" <<0;
		//INSERT INTO `SerialNumber` VALUES ('0093ab601b16a8fdac4d72a6105ad85f', 'dda2', '5', '2013-12-3 14:45', '16888', '16', '0');
		//ss_tab << strServer.GetString() << "\t" << strType.GetString() << "\t" << time_buffer << "\t"  << nRand << "\t" << i <<"\t" <<0;
		
		md5.reset();
		md5.update(ss_premd5.str());
		md5.toString();
		string strMd5 = md5.toString();
		string serial_number = md52serialnumber(strMd5); //数字转换下 

		//ss_tab <<"INSERT INTO card  (card_id, type, create_item_id, create_time) VALUES ('"<<serial_number.c_str()<< "',"<<strType.GetString() << ","<<str_item_id.GetString()<< ","<<tt ")";

		ss_tab <<"INSERT INTO card  (card_id, type, create_item_id, create_time) VALUES ('"<<serial_number.c_str()<<"',"<<strType.GetString()<<","<<str_item_id.GetString()<<","<<tt<<");";
// 		strAll_sql += serial_number;
// 		strAll_sql += "\t";
		strAll_sql += ss_tab.str();
		strAll_sql += "\r\n";

		keys += serial_number;
		keys += "\r\n";

	}

	//MessageBox(strAll.c_str());
	
	ofstream of_sql, of;

	of.open(strSave.GetString(),ios::binary);
	of.write(keys.c_str(),keys.size());
	of.close();

	
	of_sql.open(strSave_sql.GetString(),ios::binary);
	of_sql.write(strAll_sql.c_str(),strAll_sql.size());
	of_sql.close();

	MessageBox(_T("保存成功！"));
		
}


CString CNumberMakerDlg::SaveAs(void)
{
	CString strRet;
	char fileName[MAX_PATH]="";
	CFileDialog dlgFile(FALSE);

 	dlgFile.m_ofn.lpstrTitle = "浏览文件";
 	dlgFile.m_ofn.lpstrFile = fileName;

 	dlgFile.m_ofn.lpstrFilter="Any file(*.*)\0*.txt;*.cpp;*.h\0";
 	dlgFile.m_ofn.lpstrDefExt = "txt";
	// show
	dlgFile.DoModal();
	strRet = dlgFile.GetPathName();	
	return strRet;
}

string CNumberMakerDlg::md52serialnumber(const string& md5)
{
	//abcdefghijklmnopqrstuvwxyz
	static char g_szChar[] = "hjkmnprstuvwxyz"; //数字替换为字符 不含o ，i l 
	static int g_nSerialSize =10;
	string strTemp = md5;		
	string::size_type pos = 0;
	for (; pos < strTemp.size(); ++pos)  
	{
		char c= strTemp.at(pos);
		if ( c>= '0' &&c <= '9')
		{
			strTemp[pos] = g_szChar[c - '0'];
		}
	}

	transform(strTemp.begin(), strTemp.end(), strTemp.begin(), ::toupper);  //转大写

	if (strTemp.size()> g_nSerialSize)
	{
		return strTemp.substr(0,g_nSerialSize);
	}
	return strTemp;
}