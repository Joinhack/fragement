
// NumberMakerDlg.h : header file
//

#pragma once
#include "afxwin.h"
#include <string>
using namespace std;


// CNumberMakerDlg dialog
class CNumberMakerDlg : public CDialogEx
{
// Construction
public:
	CNumberMakerDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	enum { IDD = IDD_NUMBERMAKER_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support


// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	DECLARE_MESSAGE_MAP()
public:
	CEdit m_szItemId;
	CEdit m_szCount;
	afx_msg void OnEnChangeEdit3();
	int m_nType;
	int m_nCount;
	afx_msg void OnBnClickedButton1();
	CEdit m_Type;
	CString SaveAs(void);
	string md52serialnumber(const string& md5);

};
