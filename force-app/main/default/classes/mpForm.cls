public class mpForm {
	// SALESFORCE-6797 PRD4,5: select-nationality
	// selectListに設定する国籍のリスト
	// データ登録先（mpOpportunity__c.RepreNationality__c）は テキスト(10) であるため各国名の文字数は10桁まで
	public static final List<String> NATIONALITY_LIST = new List<String>{
		'インド',
		'タイ',
		'ネパール',
		'バングラデシュ',
		'フィリピン',
		'ブラジル',
		'ベトナム',
		'ミャンマー',
		'韓国',
		'中国'
	};
	// 「その他」の定数
	public static final String NATIONALITY_OTHER = 'other';
	private ApexPages.StandardController controller;
	transient public String urlValVisualforce {get;set;}
	public Id PageId;
	public Id OrderProId;
	public Integer Count {get;set;}
	public String Bankinfo {get;set;}
	public String Error {get;set;}
	public boolean NoMpOppRec {get;set;}
	//FSA対応
	public mpBeneficialOwnerController mpBOController {get;set;}

	public boolean OutPicTaken {get;set;}
	public boolean InPicTaken {get;set;}
	public boolean beforeOpenPicTaken1 {get;set;}
	public boolean beforeOpenPicTaken2 {get;set;}
	public boolean beforeOpenPicTaken3 {get;set;}
	public boolean beforeOpenPicTaken4 {get;set;}
	
	public boolean StorePicCannotTakenNow {get;set;}
	public boolean BeforeOpenStorePicCannotTakenNow {get;set;}
	public boolean BeforeOpenStorePicShouldBeTaken {get;set;}
	public String selectedPayPayMyStorePlan{get;set;} // 1:ライトプラン 2:制限プラン
	public String selectedLightplanEffectiveDate{get;set;}
	// 登録済みの場合に画面表示（リストの初期選択）のために使用する変数
	public String selectedRepreNationality {get{return selectedRepreNationality == null?'':selectedRepreNationality;}set;}
	public List<SelectOption> customAsynOnboardingTypes{
		get{
			List<SelectOption> options = new List<SelectOption>();

			// アタックリストの「非同期オンボーディング」選択リストを取得し、登録済みの選択値を取得します
			Schema.DescribeFieldResult fieldResult = mpOpportunity__c.AsynchronousOnboarding__c.getDescribe();
			List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
			// 有効の選択肢のみを追加
			for( Schema.PicklistEntry e : picklistEntries ){
				if (e.isActive()) {
					options.add(new SelectOption(e.getValue(), e.getLabel()));
				}
			}
			return options;
		}
	}

	private Map<String, Boolean> uploadedFiles;

	@TestVisible private static Boolean isDMLException = false;

	//銀行検索用
	@RemoteAction
	public static List<Map<String, String>> initSearchBank() {
		transient List<Map<String, String>> retval = new List<Map<String, String>>();

		retval.add(new Map<String, String>{'value' => '0001', 'label' => 'みずほ銀行'});
		retval.add(new Map<String, String>{'value' => '0005', 'label' => '三菱ＵＦＪ銀行'});
		retval.add(new Map<String, String>{'value' => '0009', 'label' => '三井住友銀行'});
		retval.add(new Map<String, String>{'value' => '0010', 'label' => 'りそな銀行'});
		retval.add(new Map<String, String>{'value' => '0033', 'label' => 'ＰａｙＰａｙ銀行'});
		retval.add(new Map<String, String>{'value' => '0036', 'label' => '楽天銀行'});

		return retval;
	}
	@RemoteAction
	public static List<Map<String, String>> SearchBank(String prmSearchTerm) {
		transient String searchTerm = '%'+prmSearchTerm+'%';
		transient List<Map<String, String>> retval = new List<Map<String, String>>();
		// transient AggregateResult[] groupedResults = [Select Max(Name) bkName ,bank_code__c From bank_code__c Where (Not Name Like '%【選択不可】%') AND (Name Like: searchTerm OR bank_code__c Like: searchTerm) Group by bank_code__c];
		transient AggregateResult[] groupedResults = [Select BankLabelName__c, BankSetName__c, BankCode__c From mpMaster__c Where RecordType.DeveloperName ='RecordTypeBankInfo' AND CanNotTransfer__c = false
		AND BankCode__c != '9900'
		AND (BankLabelName__c Like: searchTerm OR BankSetName__c Like: searchTerm OR BankCode__c Like: searchTerm) Group by BankCode__c, BankLabelName__c, BankSetName__c Order by BankCode__c];
		for(AggregateResult agRet : groupedResults){
			if(String.valueOf(agRet.get('BankLabelName__c')).contains(prmSearchTerm) || String.valueOf(agRet.get('BankSetName__c')).contains(prmSearchTerm) || String.valueOf(agRet.get('BankCode__c')).contains(prmSearchTerm)){
				retval.add(new Map<String, String>{
						'value' => String.valueOf(agRet.get('BankCode__c'))
					  , 'label' => String.valueOf(agRet.get('BankSetName__c'))
				});
			}
		}
		return retval;
	}
	@RemoteAction
	public static List<Map<String, String>> SearchBank_BranchOffice(String prmbankCode, String prmbankName, String prmSearchTerm){
		transient String searchTerm = '%'+prmSearchTerm+'%';
		transient List<Map<String, String>> retval = new List<Map<String, String>>();
		// transient List<bank_code__c> banks = [Select Name ,shiten_code__c From bank_code__c Where (Not Name Like  '%【選択不可】%') AND bank_code__c =: prmbankCode AND (Name Like: searchTerm OR shiten_code__c Like: searchTerm)];
		transient List<mpMaster__c> branchs = [Select BankBranchLabelName__c, BankBranchSetName__c ,BankBranchCode__c
		 From mpMaster__c
		 Where RecordType.DeveloperName ='RecordTypeBankInfo'
		  AND CanNotTransfer__c = false
		  AND BankCode__c =: prmbankCode
		  AND BankSetName__c =: prmbankName
		  AND BankCode__c != '9900'
		  AND (BankBranchLabelName__c Like: searchTerm OR BankBranchSetName__c Like: searchTerm OR BankBranchCode__c Like: searchTerm)
		 ORDER BY BankBranchCode__c];

		for(mpMaster__c bk : branchs){
			retval.add(new Map<String, String>{
					'value' => String.valueOf(bk.BankBranchCode__c),
					'label' => String.valueOf(bk.BankBranchSetName__c)
			});
		}
		return retval;
	}

	// 法人番号API
	@RemoteAction
	@AuraEnabled
	public static Map<String, String> SearchCorporateInfo(String corporateNumber){
		Map<String, String> result;

		try {
			HttpRequest req = new HttpRequest();
			String id = 'KbvjhZTQPbje4';
			req.setEndpoint('https://api.houjin-bangou.nta.go.jp/3/num?id='+id+'&number='+corporateNumber+'&type=12&history=0');
			req.setMethod('GET');

			Http h = new Http();
			HttpResponse res = h.send(req);

			// レスポンス解析
			Dom.Document doc = res.getBodyDocument();
			Dom.XMLNode corporations = doc.getRootElement();

			result = new Map<String, String>();
			result.put('error', '0');

			String count = corporations.getChildElement('count', null).getText();
			Dom.XMLNode corporation = corporations.getChildElement('corporation', null);
			result.put('count', count);
			if ('1'.equals(count) && corporation != null) {
				String tmpString;
				for (String name : new String[]{'name', 'furigana', 'postCode', 'prefectureName', 'cityName', 'streetNumber'}) {
					tmpString = corporation.getChildElement(name, null).getText();
					if (tmpString == null) {
						tmpString = '';
					}
					result.put(name, tmpString);
				}
				// 郵便番号にハイフンを入れる
				if (Pattern.matches('[0-9]{7}', result.get('postCode'))) {
					result.put('postCode', '' + result.get('postCode').substring(0, 3) + '-' + result.get('postCode').substring(3, 7));
				}
			}
		} catch (Exception e) {
			// 法人番号APIがメンテ、ID違い、など

			// エラーフラグだけ返す
			result = new Map<String, String>();
			result.put('error', '1');
		}
		return result;
	}

	//生年月日入力 西暦和暦併記用
	public String customerBirthYearVal {get{return customerBirthYearVal == null?'0000':customerBirthYearVal;}set;}
	public String customerBirthMonthVal {get{return customerBirthMonthVal == null?'':customerBirthMonthVal;}set;}
	public String customerBirthDayVal {get{return customerBirthDayVal == null?'':customerBirthDayVal;}set;}
	public String birthYearVal {get{return birthYearVal == null?'0000':birthYearVal;}set;}
	public String birthMonthVal {get{return birthMonthVal == null?'':birthMonthVal;}set;}
	public String birthDayVal {get{return birthDayVal == null?'':birthDayVal;}set;}
	public String merchantOpenYearVal {get{return merchantOpenYearVal == null?'0000':merchantOpenYearVal;}set;}
	public String merchantOpenMonthVal {get{return merchantOpenMonthVal == null?'':merchantOpenMonthVal;}set;}
	public String merchantOpenDayVal {get{return merchantOpenDayVal == null?'':merchantOpenDayVal;}set;}

		public String yearVal {get{return yearVal == null?'0000':yearVal;}set;}
		public List<SelectOption> getYearlist(){
			List<selectOption> options = new List<selectOption>();
			for (Integer i = Date.today().year()-150; i < Date.today().year()-15; i++) {
				if (i > 1988) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [平成'+ String.valueOf(i - 1988)+'] 年'));
				else if (i > 1925) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [昭和'+ String.valueOf(i - 1925)+'] 年'));
				else if (i > 1911) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [大正'+ String.valueOf(i - 1911)+'] 年'));
				else if (i > 1867) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [明治'+ String.valueOf(i - 1867)+'] 年'));
				else options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' 年'));
				if(i == Date.today().year()-35) options.add(new selectOption('0000', '-- 年 -- 選択してください '));
			}
			return options;
		}
		//open前用
		public List<SelectOption> getStoreOpenYearlist(){
			List<selectOption> options = new List<selectOption>();
			for (Integer i = Date.today().year(); i < Date.today().year()+15; i++) {
				if (i > 1988) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [平成'+ String.valueOf(i - 1988)+'] 年'));
				else if (i > 1925) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [昭和'+ String.valueOf(i - 1925)+'] 年'));
				else if (i > 1911) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [大正'+ String.valueOf(i - 1911)+'] 年'));
				else if (i > 1867) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [明治'+ String.valueOf(i - 1867)+'] 年'));
				else options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' 年'));
				if(i == Date.today().year()-40) options.add(new selectOption('0000', '-- 年 --'));
			}
			return options;
		}
		public List<SelectOption> getMonthlist(){
			List<selectOption> options = new List<selectOption>();
			options.add(new selectOption('00', '-- 月 -- 選択してください '));
			for (Integer i = 0; i < 12; i++) {
				options.add(new selectOption(String.valueOf(i+1).leftPad(2, '0'), String.valueOf(i+1).leftPad(2, '0')+' 月'));
			}
			return options;
		}
		public List<SelectOption> getDaylist(){
			List<selectOption> options = new List<selectOption>();
			options.add(new selectOption('00', '-- 日 -- 選択してください '));
			for (Integer i = 0; i < 31; i++) {
				options.add(new selectOption(String.valueOf(i+1).leftPad(2, '0'), String.valueOf(i+1).leftPad(2, '0')+' 日'));
			}
			return options;
		}

	/*
	* @description      国籍用selectListの組み立て
	* @param 			無し
	* @return           国籍の選択リスト値をまとめたListクラスのインスタンス
	*/
	public List<SelectOption> getNationalityList(){
		List<selectOption> options = new List<selectOption>();
		// 常に先頭に"--国名を選択してください--"を設定
		options.add(new selectOption('', '--国名を選択してください--'));
		for(String nationality : NATIONALITY_LIST) {
			options.add(new selectOption(nationality, nationality));
		}
		options.add(new selectOption(NATIONALITY_OTHER, 'その他'));
		return options;
	}

	public Attachment attachment {
		get {
		if (attachment == null)
		attachment = new Attachment();
		return attachment;
		}
		set;
	}

	public Attachment attachment2 {
		get {
		if (attachment2 == null)
		attachment2 = new Attachment();
		return attachment2;
		}
		set;
	}

	public Attachment attachment3 {
		get {
		if (attachment3 == null)
		attachment3 = new Attachment();
		return attachment3;
		}
		set;
	}

	public Attachment attachment4 {
		get {
		if (attachment4 == null)
		attachment4 = new Attachment();
		return attachment4;
		}
		set;
	}

	public Attachment attachment5 {
		get {
		if (attachment5 == null)
		attachment5 = new Attachment();
		return attachment5;
		}
		set;
	}

	public Attachment attachment6 {
		get {
		if (attachment6 == null)
		attachment6 = new Attachment();
		return attachment6;
		}
		set;
	}

	public Attachment attachmentOut {
		get {
		if (attachmentOut == null)
		attachmentOut = new Attachment();
		return attachmentOut;
		}
		set;
	}

	public Attachment attachmentIn {
		get {
		if (attachmentIn == null)
		attachmentIn = new Attachment();
		return attachmentIn;
		}
		set;
	}
	
	public Attachment beforeOpenattachment1 {
		get {
		if (beforeOpenattachment1 == null)
		beforeOpenattachment1 = new Attachment();
		return beforeOpenattachment1;
		}
		set;
	}
	
	public Attachment beforeOpenattachment2 {
		get {
		if (beforeOpenattachment2 == null)
		beforeOpenattachment2 = new Attachment();
		return beforeOpenattachment2;
		}
		set;
	}
	
	public Attachment beforeOpenattachment3 {
		get {
		if (beforeOpenattachment3 == null)
		beforeOpenattachment3 = new Attachment();
		return beforeOpenattachment3;
		}
		set;
	}
	
	public Attachment beforeOpenattachment4 {
		get {
		if (beforeOpenattachment4 == null)
		beforeOpenattachment4 = new Attachment();
		return beforeOpenattachment4;
		}
		set;
	}

	// SALESFORCE-6797 SCフォーム改修 PRD18
	// 添付ファイルフォーム（AttachmentForm__c）と同じURLを取得する
	public String fileUploadFormUrl{ 
		get {
			if (fileUploadFormUrl == null) {
				if (!CommonUtil.isSandboxOrg()) {
					fileUploadFormUrl = System.Label.SiteDomainURL + '/attachment2?target=';
				} else {
					fileUploadFormUrl = URL.getOrgDomainUrl().toExternalForm().replace('salesforce.com', 'salesforce-sites.com/mpAttachmentForm2?target=');
				}
			}

			fileUploadFormUrl += this.PageId;
			return fileUploadFormUrl;
		}
	 	private set;
	 }

	public PageReference mpResendMail() {
		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();
		mp.ReSendMail__c = 'Resend' + DateTime.now().format('yyyy-MM-dd HH:mm:ss');
		try {
			update mp;
		} catch (DmlException e) {

				mp.addError('システムエラー：保存されたデータに不備があります。修正後、再度フォームを開いてください');

			return null;
		}
		PageReference ref = new PageReference('/apex/mpFormEmail');
		ref.setRedirect(true);
		ref.getParameters().put('id', mp.Id);
		return ref;
	}

	public PageReference mpResendMailConfirm() {
		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();
		mp.ReSendMailConfirm__c = 'ResendConfirm' + DateTime.now().format('yyyy-MM-dd HH:mm:ss');
		try {
			update mp;
		} catch (DmlException e) {
			mp.addError('システムエラー：保存されたデータに不備があります。修正後、再度フォームを開いてください');
			return null;
		}
		PageReference ref = new PageReference('/apex/mpFormEmail');
		ref.setRedirect(true);
		ref.getParameters().put('id', mp.Id);
		return ref;
	}

	public PageReference DailyReportSave() {
		mpComm__c mp = (mpComm__c) controller.getRecord();
		insert mp;
		PageReference ref = new PageReference('https://yahoojp-marketing.my.salesforce.com');
		ref.setRedirect(true);
		//ref.getParameters().put('id', mp.Id);
		return ref;
	}

   //FSA対応
	public mpForm () {
	}

	//FSA対応
	public PageReference updateBenlOwner() {
		// Boolean result = mpFormBenlOwnerController.updateData(mpFormBenlOwnerController);
		// PageId = ApexPages.currentPage().getParameters().get('id');
		// PageReference ref = null;
		// if(result){
		//     ref = new PageReference('/apex/mpFormInfoConfirm');
		//     ref.setRedirect(true);
		//     ref.getParameters().put('id', PageId);
		//     return ref;
		// }else{
		//     PageId = ApexPages.currentPage().getParameters().get('id');
		//     ref = new PageReference('/apex/BeneficialOwnerForm');
		//     ref.setRedirect(true);
		//     ref.getParameters().put('id', PageId);
		// }
		// return ref;
		return null;
	}

	public List<SelectOption> getPayCycleOptions() {
		List<SelectOption> options = new List<SelectOption>{
			new SelectOption('', '--なし--')
		};

		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();
		if (mp != null) {
			Httprequest req = new HttpRequest();
			req.setEndpoint(
				URL.getOrgDomainUrl().toExternalForm() +
				'/services/data/v50.0/ui-api/object-info/mpOpportunity__c' +
				'/picklist-values/' +
				mp.RecordTypeId +
				'/PayCycle__c'
			);
			req.setMethod('GET');
			req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
			req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
			try {
				Http http = new Http();
				HttpResponse res = http.send(req);
				Map<String, Object> respBodyMap = (Map<String, Object>) Json.deserializeUntyped(
					res.getBody()
				);
				List<object> valuesObjList = (List<object>) respBodyMap.get('values');
				List<string> pickValues = new List<string>();
				for (object obj : valuesObjList) {
					Map<string, object> valuesMap = (map<string, object>) obj;
					options.add(new SelectOption((string) valuesMap.get('label'), (string) valuesMap.get('value'))); 
				}
			} catch (Exception e) {
				Schema.DescribeFieldResult cyclefield =  mpOpportunity__c.PayCycle__c.getDescribe();
				List<Schema.PicklistEntry> picklist = cyclefield.getPicklistValues();
				for( Schema.PicklistEntry f : picklist){ 
					options.add(new SelectOption(f.getLabel(), f.getValue())); 
				}
			}
		}
		return options;
	}

	// 初期呼び出し：サービス管理（決済事業）からフォームを起動した場合はアタックリストIDに変えてリダイレクトさせる
	public PageReference firstRedirectcheck() {

		String pageURL = Apexpages.currentPage().getUrl();
		// PayPayアタックリストからもしくはmpFormEmail以外の画面呼び出しの場合
		if (String.isBlank(String.valueOf(OrderProId)) || !pageURL.contains('mpFormEmail')) {
			return null;
		} else { //サービス管理（決済事業）からの呼び出しの場合
			List<OrderProgress__c> opRec = [SELECT Id, mpOpportunityRelatedFlg__c, AccountId__c, AccountId__r.Name, OwnerId,
												OpportunityId__r.Staffid__c, OpportunityId__r.IntroducedCode__c, OpportunityId__r.restaurant__c
												FROM OrderProgress__c WHERE Id = :OrderProId];

			List<mpOpportunity__c> mpOppRec = [SELECT Id FROM mpOpportunity__c WHERE OrderProgressId__c = :OrderProId];
			// サービス管理に既にアタックリストが作成されている場合
			if (!mpOppRec.isEmpty()) {
				PageId = mpOppRec[0].Id;
			}
			//アタックリストが作成されていない場合
			else {
				String recId = mpUtilString.getRecordTypeByDeveloperName(mpOpportunity__c.sObjectType, 'mpList');
				mpOpportunity__c mp = new mpOpportunity__c(
					Name = opRec[0].AccountId__r.Name,
					OrderProgressId__c = OrderProId,
					AccountId__c = opRec[0].AccountId__c,
					RecordTypeId = recId,
					// アタックリストの所有者にサービス管理の所有者を設定
					OwnerId = opRec[0].OwnerId,
					staffid__c = opRec[0].OpportunityId__r.Staffid__c,
					IntroducedCode__c = opRec[0].OpportunityId__r.IntroducedCode__c,
					restaurant__c = opRec[0].OpportunityId__r.restaurant__c
				);
				// サービス管理（決済事業）.アタックリスト有無フラグをtrueに変更
				opRec[0].mpOpportunityRelatedFlg__c = true;

				try {
					// PayPayアタックリストの作成
					insert mp;
					// 起動サービス管理の更新
					update opRec[0];

					if (Test.isRunningTest() && isDMLException) {
						insert new Account();
					}
				} catch (DmlException e) {
					Error = 'システムエラー：フォームの呼び出しに失敗しました。';
					NoMpOppRec = true;
					return null;
				}
				PageId = mp.Id;
			}
		}
		// 申し込み画面へ遷移
		PageReference ref = new PageReference('/apex/mpFormEmail');
		ref.setRedirect(true);
		ref.getParameters().put('id', PageId);
		return ref;
	}

	public mpForm (ApexPages.StandardController controller) {
		String pageURL = Apexpages.currentPage().getUrl();
		this.controller = controller;
		Error='';
		selectedPayPayMyStorePlan = '';
		PageId = ApexPages.currentPage().getParameters().get('id');
		OrderProId = ApexPages.currentPage().getParameters().get('opid');
		
		// サービス管理（決済事業）レコードIDがパラメータにない場合の処理
		// SALESFORCE-6797 PRD4,5: select-nationality
		if (!String.isBlank(String.valueOf(PageId))) {
			List<mpOpportunity__c> CurrentRec = [SELECT FormCustomerName__c,FormCustomerKanaName__c, FormCustomerPhone__c, FormCustomerDepartment__c,
				Name, RepresentativeName__c, RepresentativeKanaName__c, Phone__c, FormBirthday__c, FormCustomerBirthday__c, estimatedOpeningDate__c,
				DeleteDuplicate__c, RepreNationality__c FROM mpOpportunity__c WHERE Id = :PageId];

			// PayPayアタックリスト.重複データがTRUEの場合は申し込みできない。
			if (CurrentRec[0].DeleteDuplicate__c) {
				Error = '重複データのため申込できません。';
			} else {
				customerBirthYearVal = null;
				customerBirthMonthVal = null;
				customerBirthDayVal = null;
				birthYearVal = null;
				birthMonthVal = null;
				birthDayVal = null;
				merchantOpenYearVal = null;
				merchantOpenMonthVal = null;
				merchantOpenDayVal = null;
				
				OutPicTaken = false;
				InPicTaken = false;
				beforeOpenPicTaken1 = false;
				beforeOpenPicTaken2 = false;
				beforeOpenPicTaken3 = false;
				beforeOpenPicTaken4 = false;
				uploadedFiles = null;

				If(!CurrentRec.isEmpty()){
					mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();

					if (CurrentRec[0].FormCustomerBirthday__c != null) {
						List<String> birthVal = CurrentRec[0].FormCustomerBirthday__c.split('/');
						customerBirthYearVal = birthVal[0];
						customerBirthMonthVal = birthVal[1];
						customerBirthDayVal = birthVal[2];
					}
					if (CurrentRec[0].FormBirthday__c != null) {
						List<String> birthVal = CurrentRec[0].FormBirthday__c.split('/');
						birthYearVal = birthVal[0];
						birthMonthVal = birthVal[1];
						birthDayVal = birthVal[2];
					}
					if (CurrentRec[0].estimatedOpeningDate__c != null) {
						List<String> birthVal = CurrentRec[0].estimatedOpeningDate__c.split('/');
						merchantOpenYearVal = birthVal[0];
						merchantOpenMonthVal = birthVal[1];
						merchantOpenDayVal = birthVal[2];
					}
					if(CurrentRec[0].FormCustomerName__c == null){
						mp.FormCustomerName__c = CurrentRec[0].RepresentativeName__c;}

					if(CurrentRec[0].FormCustomerKanaName__c == null){
						mp.FormCustomerKanaName__c = CurrentRec[0].RepresentativeKanaName__c;}

					if(!pageURL.contains('mpFormInfoReview')&&!pageURL.contains('mpFormInfoBeforeVisit')&&CurrentRec[0].FormCustomerPhone__c == null){
						mp.FormCustomerPhone__c = CurrentRec[0].Phone__c;}

					// SALESFORCE-6797 PRD4,5: select-nationality
					// 代表者情報_国籍（RepreNationality__c）に値が登録済みの場合、画面表示のため判定
					if ((CurrentRec[0].RepreNationality__c != null) && (CurrentRec[0].RepreNationality__c != '')) {
						if (NATIONALITY_LIST.contains(CurrentRec[0].RepreNationality__c)) {
							// 国籍のリスト項目に存在する場合はリストを選択用の変数に設定
							selectedRepreNationality = CurrentRec[0].RepreNationality__c;
						} else {
							// 値が入っていてリストにない場合は「その他」と判断
							selectedRepreNationality = NATIONALITY_OTHER;
						}
					}
				}
			}
		}
		this.mpBOController = new mpBeneficialOwnerController(PageId);
	}

	//ランダム整数生成
	public static string getRandomString(Integer LengthRequired){
		String CharList = '1234567890';
		String Res = '';
		integer position;
		for(Integer i = 0; i <= LengthRequired; i++) {
			position = Integer.valueof(String.valueof(Math.roundToLong(CharList.length()*Math.random()))) -1;
			if(position < 0){
				position = 0;
			}
			Res += CharList.substring(position,position+1);
		}
		return Res;
	}

	// 確認コード発番
	@TestVisible
	private String makeVerifyCode(String id) {
		try {
			String email = [Select FormCustomerEmail__c From mpOpportunity__c Where Id = :id].FormCustomerEmail__c;
			return makeVerifyCode(id, email);
		} catch (Exception e) {
			return '0000';
		}
	}

	private String makeVerifyCode(String id, String email) {
		try {
			String code = EncodingUtil.convertToHex(
				Crypto.generateDigest( 'SHA-256', Blob.valueOf( '_' + id + '_paypay_sales_' +email + '_' )));
			return ''
			 + ('0' + (code.length() - code.replaceAll('[01]', '').length())).right(1) // 0と1の個数の下1桁
			 + ('0' + (code.length() - code.replaceAll('[789]', '').length())).right(1) // 7と８と９の個数の下1桁
			 + ('0' + (code.length() - code.replaceAll('[ABCabc]', '').length())).right(1) // abcの個数の下1桁
			 + ('0' + (code.length() - code.replaceAll('[EFef]', '').length())).right(1) // efの個数の下1桁
			 ;
		} catch (Exception e) {
			return '0000';
		}
	}

	private Boolean isMagicVerifyCode(String code) {
			List<mpMaster__c> result = [Select id FROM mpMaster__c Where (SalesVerifyMagicNumber__c  = :code) and RecordType.DeveloperName = 'RecordTypeSalesVerifyMagicNumber'];
			if (result.isempty()) {
				return false;
			} else {
				return true;
			}
	}

	public String getVerifyCode() {
		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();
		return makeVerifyCode(mp.id);
	}

	public Map<String, String> getNewMerchantCampSetting() {
		return mpNewMerchantCamp.getCampaignSetting();
	}

	public PageReference mpVerifyCode() {

		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();

		if (mp.Parameter_Confirmation__c == '') {
			Error = '確認コードを入力してください。';
			return null;
		}
		if (mp.Parameter_Confirmation__c != makeVerifyCode(mp.Id)) {
			if (!isMagicVerifyCode(mp.Parameter_Confirmation__c)) {
				Error = '確認コードが正しくありません。';
				return null;
			}
		}

		update mp;

		PageReference ref = new PageReference('/apex/mpFormInfo');
		ref.setRedirect(true);
		ref.getParameters().put('id', mp.Id);
		return ref;
	}

	// 確認コードのチェック
	public PageReference redirectcheck() {
		OutPicTaken = isUploadedCheck('店舗外観写真');
		InPicTaken = isUploadedCheck('店舗内観写真');
		beforeOpenPicTaken1 = isUploadedCheck('開店前店舗資料1');
		beforeOpenPicTaken2 = isUploadedCheck('開店前店舗資料2');
		beforeOpenPicTaken3 = isUploadedCheck('開店前店舗資料3');
		beforeOpenPicTaken4 = isUploadedCheck('開店前店舗資料4');
		List<mpOpportunity__c> mp = [Select id, Parameter_Confirmation__c, FormCustomerEmail__c, yahoojp_18_Id__c FROM mpOpportunity__c Where id =: PageId];

		if (mp.isEmpty()) {
			// データが無い場合は最終的にエラー画面にいくので何もしない
			return null;
		}

		String verify_user_param = mp[0].Parameter_Confirmation__c;
		if (verify_user_param == null || (verify_user_param != makeVerifyCode(mp[0].Id, mp[0].FormCustomerEmail__c) && !isMagicVerifyCode(verify_user_param))) {
			if (verify_user_param == null || String.isBlank(mp[0].yahoojp_18_Id__c) || verify_user_param != makeVerifyCode(mp[0].yahoojp_18_Id__c, mp[0].FormCustomerEmail__c)) {
				// 認証失敗
				PageReference ref = new PageReference('/apex/mpFormEmailConfirm');
				ref.setRedirect(true);
				ref.getParameters().put('id', mp[0].Id);
				return ref;
			}
		}

		return null;
	}

	public PageReference NextStep() {

		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();

		try {
			update mp;
		} catch (DmlException e) {

				mp.addError('システムエラー：保存されたデータに不備があります。修正後、再度フォームを開いてください');

			return null;
		}
		PageReference ref = new PageReference('/apex/mpFormInfo');
		ref.setRedirect(true);
		ref.getParameters().put('id', mp.Id);
		return ref;
	}

	public Boolean isMoneyOnlyProduct{
		get{
			List<mpOpportunity__c> originalMp = [Select ProductName__c FROM mpOpportunity__c Where id =: PageId];
			return (!originalMp.isEmpty() && originalMp[0].ProductName__c != null && originalMp[0].ProductName__c.contains('マネー限定'));
		}
	}
	public Boolean isBalanceOnlyProduct{
		get{
			List<mpOpportunity__c> originalMp = [Select ProductName__c FROM mpOpportunity__c Where id =: PageId];
			return (!originalMp.isEmpty() && originalMp[0].ProductName__c != null && originalMp[0].ProductName__c.contains('残高限定'));
		}
	}
	
	public Boolean isAlipayNotCoveredProduct {
		get{
			List<String> notCoveredProduct = new List<String>();
			for (ProductNameNotCoveredbyAlipay__mdt productList :[
					SELECT DeveloperName, MasterLabel
					FROM ProductNameNotCoveredbyAlipay__mdt
					ORDER BY MasterLabel
					]) {
				notCoveredProduct.add(productList.MasterLabel);
			} 
			List<mpOpportunity__c> originalMp = [Select ProductName__c FROM mpOpportunity__c Where id =: PageId];
			return (!originalMp.isEmpty() && originalMp[0].ProductName__c != null && notCoveredProduct.contains(originalMp[0].ProductName__c));
		}
	} 

	public Boolean isSkipProductForLightPlan{
		get{
			List<String> skipPageList = new List<String>();
			for (PageSkipList__mdt nameList :[
					SELECT DeveloperName, MasterLabel
					FROM PageSkipList__mdt
					ORDER BY MasterLabel
				]) {
				skipPageList.add(nameList.MasterLabel);
			}
			List<mpOpportunity__c> originalMp = [Select ProductName__c FROM mpOpportunity__c Where id =: PageId];
			return (!originalMp.isEmpty() && originalMp[0].ProductName__c != null && skipPageList.contains(originalMp[0].ProductName__c));
		}
	}
	

	public PageReference mpRedirect() {
		urlValVisualforce = Apexpages.currentPage().getUrl();
		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();

		PageId = ApexPages.currentPage().getParameters().get('id');
		List<mpOpportunity__c> OriginalStatus = [Select id,
			IntroducedCode__c, FormCustomerEmail__c, ReviewStatus__c, Status__c, HiddenStatus__c,
			DepositAccountType__c, AgreementType__c,
			CommissionTargetFlag__c, CommissionPercentage__c, PayCyclePattern__c, CommissionSpecialRate__c,
			LastName__c, FirstName__c, FormCustomerKanaNameLast__c, FormCustomerKanaNameFirst__c, FormCustomerBirthday__c,
			PostalCode__c, Prefectures__c, City__c, TownName__c, FormSectionStreetNumber__c, BuildingNumber__c,estimatedOpeningDate__c,qdditionalRemittanceMatters__c, InfoAgreementCheck__c, InfoNonAgreement__c
			FROM mpOpportunity__c Where id =: PageId];
		if(BeforeOpenStorePicShouldBeTaken==false&&string.isNotBlank(mp.estimatedOpeningDate__c)){
			mp.estimatedOpeningDate__c = '';
		}
		//controller.save();

		// 1st Step - Emailページ
		if (urlValVisualforce.contains('mpFormEmail') && mp.FormCustomerEmail__c != null){

			if (OriginalStatus[0].Status__c == '申込済み' && String.isNotBlank(OriginalStatus[0].ReviewStatus__c)) {
				Error = '申込済みのため変更できません。';
				return null;
			}

			//携帯会社のメールアドレスのバリデーション
			String CarrierMailDomain = mp.FormCustomerEmail__c.substringAfter('@');
			String DoubleCarrierMailDomain = CarrierMailDomain.substringAfter('.');
			List< mpMaster__c > checkEmail = [Select id FROM mpMaster__c Where (domain__c =: CarrierMailDomain or domain__c =: DoubleCarrierMailDomain) and RecordType.DeveloperName = 'RecordTypeCellDomain'];
			If(!checkEmail.isEmpty()){
				Error = '入力されたメールアドレスは登録に利用できません。携帯会社以外のメールアドレスを利用ください。';
				return null;
			}
			//キャンペーンコードのバリデーション
			if(mp.IntroducedCode__c != null){

			   if(mp.IntroducedCode__c.length() ==11&& (mp.IntroducedCode__c.startsWith('090') || mp.IntroducedCode__c.startsWith('080') || mp.IntroducedCode__c.startsWith('070') || mp.IntroducedCode__c.startsWith('060'))){
					//正しい携帯電話番号であればスルー
				}
				else if(mp.IntroducedCode__c == 'CBB2018'){
					//千葉県美容組合案件の紹介コードの場合はスルー
				}
				else if(mp.IntroducedCode__c.startsWith('PayPay')){
					//PayPayスタート文字は斡旋テストでスルー
				}
				else if(mp.IntroducedCode__c.startsWith('inv')){
					//invスタート文字はユーザ紹介でスルー
				}
				//SBA代理店キャンペーン
				else if(mp.IntroducedCode__c.length() ==10 && mp.IntroducedCode__c.startsWith('SBA')){
					List<mpIntroducer__c> CodeCheck = [Select id, RelatedmpOpportunity__c FROM mpIntroducer__c Where SBACode__c =: mp.IntroducedCode__c limit 1];
					If(!CodeCheck.isEmpty()){
						mp.Introducedmp__c = CodeCheck[0].RelatedmpOpportunity__c;
					}else{
						Error = '入力された紹介者コードは、無効です。<br />紹介者コードを今一度ご確認のうえ入力をお願いします。';
						return null;
					}
				}
				//紹介者キャンペーンと斡旋獲得依頼
				else if (! String.isBlank(mp.IntroducedCode__c)){
					//紹介者キャンペーンコード Code__c
					List<mpIntroducer__c> CodeCheck = [Select id, RelatedmpOpportunity__c FROM mpIntroducer__c Where Code__c =: mp.IntroducedCode__c limit 1];
					If(!CodeCheck.isEmpty()){
						//紹介した加盟店と紐付け
						mp.Introducedmp__c = CodeCheck[0].RelatedmpOpportunity__c;
					}else{
						//紹介者キャンペーンではない場合、斡旋の場合あり
						List< mpMaster__c > AssenCheck = [Select id, IntermediaryAgentCode__c FROM mpMaster__c Where RecordType.DeveloperName = 'RecordTypeMediation' and IntermediaryAgentCode__c =: mp.IntroducedCode__c limit 1];
						//斡旋データのコードが一致しない場合（一致した場合は特にアクションがないためスルー）
						If(!AssenCheck.isEmpty()){
							//斡旋のデータの場合は、スルー
						}else{
							Error = '入力されたコードは、ご利用できません。正しいコードをご確認ください。<br />';
							return null;
						}
					}
				}
				else{
						Error = '入力されたコードは、ご利用できません。正しいコードをご確認ください。';
						return null;
				}
			}

			if(OriginalStatus[0].Status__c != 'Email確認済' && OriginalStatus[0].Status__c != '店舗情報入力済' && OriginalStatus[0].Status__c != '口座・許認可情報入力済み' && OriginalStatus[0].Status__c != '申込済み'  ){
				mp.Bizcard__c = false; //名刺で取り込んだ情報をFalseに変更
				mp.Status__c = 'Email確認済';
				mp.HiddenStatus__c = 'Email確認済';
				mp.EmailCompleteDate__c = date.today();
				mp.password__c = getRandomString(3);
			}
			if (OriginalStatus[0].FormCustomerEmail__c != mp.FormCustomerEmail__c) {
				mp.Parameter_Confirmation__c = '';
			}

			try {
				update mp;
			} catch (DmlException e) {

					mp.addError('システムエラー：保存されたデータに不備があります。修正後、再度フォームを開いてください');

				return null;
			}
			//controller.save();
			PageReference ref = new PageReference('/apex/mpFormInfo');
			ref.setRedirect(true);
			ref.getParameters().put('id', mp.Id);
			return ref;
		}

		// 2st Step - 申し込みページ
		else if (urlValVisualforce.contains('mpFormInfo') && mp.FormCustomerEmail__c != null){
			if(!StorePicCannotTakenNow&&!BeforeOpenStorePicShouldBeTaken){
				if((!getIsUploadedStoreOutCheck() && attachmentOut.Body == null)
				   || (!getIsUploadedStoreInCheck() && attachmentIn.Body == null)) {
					   Error = '店舗画像が添付されていません。';
					   attachmentOut = new Attachment();
					   attachmentIn = new Attachment();
					   return null;
				   }
				if(attachmentOut.Body != null||attachmentIn.Body != null){
					upload();
				}
			}

			if(BeforeOpenStorePicShouldBeTaken){//!BeforeOpenStorePicCannotTakenNow&&
				if((!getIsUploadedBeforeOpenStoreCheck() && beforeOpenattachment1.Body == null)) {
					   Error = '店舗画像が添付されていません。';
					   beforeOpenattachment1 = new Attachment();
					   return null;
				   }
				if(beforeOpenattachment1.Body != null||beforeOpenattachment2.Body != null||beforeOpenattachment3.Body != null||beforeOpenattachment4.Body != null){
					upload();
				}
			} else {
				mp.estimatedOpeningDate__c = '';
			}
			
			
			if (OriginalStatus[0].Status__c == '申込済み' && String.isNotBlank(OriginalStatus[0].ReviewStatus__c)) {
				Error = '申込済みのため変更できません。';
				return null;
			}

			if (String.isNotBlank(mp.ProductName__c)) {
				if (mp.ProductName__c.contains('マネー限定') || mp.ProductName__c.contains('残高限定')) {
					if (!mp.AgreementOfWalletOnlyPrecaution__c) {
						Error = '必須の同意事項が選択されていません。';
					}
				} else {
					mp.AgreementOfWalletOnlyPrecaution__c = false;
				}
				if (mp.ProductName__c.contains('特定継続的役務')) {
					if (!mp.AgreementOfSpecifiedContinuousServices__c) {
						Error = '必須の同意事項が選択されていません。';
					}
				} else {
					mp.AgreementOfSpecifiedContinuousServices__c = false;
				}
				if (Error != '') {
					return null;
				}
			}

			// SALESFORCE-6797 PRD20 ↓↓
			if(attachment.body != null){
				attachment.ParentId = mp.Id ;
				attachment.Name =  '許認可情報_' + attachment.Name;
				attachment.IsPrivate = false;
				try {
				insert attachment;
				} catch (DMLException e) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
				return null;
				} finally {
				attachment = new Attachment();
				}
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Attachment uploaded successfully'));
			}

			if(attachment2.body != null){
				attachment2.ParentId = mp.Id ;
				attachment2.Name =  '許認可情報_' + attachment2.Name;
				attachment2.IsPrivate = false;
				try {
				insert attachment2;
				} catch (DMLException e) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
				return null;
				} finally {
				attachment2 = new attachment();
				}
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'attachment2 uploaded successfully'));
			}

			if(attachment3.body != null){
				attachment3.ParentId = mp.Id ;
				attachment3.Name =  '許認可情報_' + attachment3.Name;
				attachment3.IsPrivate = false;
				try {
				insert attachment3;
				} catch (DMLException e) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
				return null;
				} finally {
				attachment3 = new attachment();
				}
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'attachment3 uploaded successfully'));
			}
			// SALESFORCE-6797 PRD20 ↑↑


			Boolean resetCommission = false;
			if (mp.AgreementType__c == '自治体契約') {
				if (String.isBlank(OriginalStatus[0].CommissionSpecialRate__c)) {
					mp.CommissionSpecialRate__c = '1.50';
					mp.CommissionPercentage__c = null;
					mp.PayCyclePattern__c = '';
				}
			} else if (OriginalStatus[0].CommissionSpecialRate__c == '1.50') {
				// 自治体専用のためクリアする
				mp.CommissionSpecialRate__c = '';
				mp.CommissionPercentage__c = null;
				resetCommission = true;
			} else if (OriginalStatus[0].CommissionPercentage__c == null) {
				mp.CommissionPercentage__c = 1.98;
			}
			if (OriginalStatus[0].CommissionTargetFlag__c && String.isBlank(OriginalStatus[0].PayCyclePattern__c)) {
				mp.PayCyclePattern__c = 'エンプラ';
				OriginalStatus[0].PayCyclePattern__c = 'エンプラ';
			}
			if (OriginalStatus[0].PayCyclePattern__c == 'エンプラ') {
				mp.Over1Agreement__c = false;
				mp.EarlyPayoutCycle__c = false;
			}

			try {
				// 入力されたデータで上書き
				if (mp.FormCustomerBirthday__c != null) {
					List<String> birthVal = mp.FormCustomerBirthday__c.split('/');
					customerBirthYearVal = birthVal[0];
					customerBirthMonthVal = birthVal[1];
					customerBirthDayVal = birthVal[2];
				}
			} catch(Exception e) {
				// 生年月日の存在しないページではエラーになるためcatchしてスルーする
			}
			try {
				// 入力されたデータで上書き
				if (mp.FormBirthday__c != null) {
					List<String> birthVal = mp.FormBirthday__c.split('/');
					birthYearVal = birthVal[0];
					birthMonthVal = birthVal[1];
					birthDayVal = birthVal[2];
				}
			} catch(Exception e) {
				// 生年月日の存在しないページではエラーになるためcatchしてスルーする
			}
			if(OriginalStatus[0].Status__c != '店舗情報入力済' && OriginalStatus[0].Status__c != '口座・許認可情報入力済み' && OriginalStatus[0].Status__c != '申込済み'  ){
				mp.Status__c = '店舗情報入力済';
				mp.HiddenStatus__c = '店舗情報入力済';
				mp.ShopInfoCompleteDate__c = date.today();
			}
			if(mp.FormSameAddress__c == true){
				mp.FormNoCorpPostalCode__c= mp.PostalCode__c;
				mp.FormNoCorpPrefectures__c= mp.Prefectures__c;
				mp.FormNoCorpCity__c =mp.City__c;
				mp.FormNoCorpCityKana__c =mp.CityKana__c;
				mp.FormNoCorpTownName__c = mp.TownName__c;
				mp.FormNoCorpTownNameKana__c = mp.TownNameKana__c;
				mp.FormNoCorpFormSectionStreetNumber__c = mp.FormSectionStreetNumber__c;
				//mp.FormNoCorpBuildingNumber__c = mp.FormSectionStreetNumberKana__c;
				mp.FormNoCorpBuildingNumber__c = mp.BuildingNumber__c;
				//mp.FormNoCorpFormBuildingNumber__c = mp.BuildingNumber__c;
				mp.FormNoCorpFormBuildingNumber__c = mp.FormBuildingNumber__c;
			}
			
			if (OriginalStatus[0].LastName__c != mp.LastName__c ||
				OriginalStatus[0].FirstName__c != mp.FirstName__c ||
				OriginalStatus[0].FormCustomerKanaNameLast__c != mp.FormCustomerKanaNameLast__c ||
				OriginalStatus[0].FormCustomerKanaNameFirst__c != mp.FormCustomerKanaNameFirst__c ||
				OriginalStatus[0].FormCustomerBirthday__c != mp.FormCustomerBirthday__c ||
				OriginalStatus[0].PostalCode__c != mp.PostalCode__c ||
				OriginalStatus[0].Prefectures__c != mp.Prefectures__c ||
				OriginalStatus[0].City__c != mp.City__c ||
				OriginalStatus[0].TownName__c != mp.TownName__c ||
				OriginalStatus[0].FormSectionStreetNumber__c != mp.FormSectionStreetNumber__c ||
				OriginalStatus[0].BuildingNumber__c != mp.BuildingNumber__c
			) {
				mp.KYCHistory__c = null;
			}
			try {
				update mp;
				if (resetCommission) {
					mpOpportunity__c resetCommissionMp = new mpOpportunity__c(
						Id = mp.Id,
						CommissionPercentage__c = 1.98
					);
					if (![Select Id From mpOpportunity__c Where Id = :mp.Id
						  AND CommissionTargetFlag__c = true AND PayCyclePattern__c = null].isEmpty()) {
							  resetCommissionMp.PayCyclePattern__c = 'エンプラ';
							  resetCommissionMp.Over1Agreement__c = false;
							  resetCommissionMp.EarlyPayoutCycle__c = false;
						  }
					update resetCommissionMp;
				}
			} catch (DmlException e) {
				for (Integer i = 0; i < e.getNumDml(); i++) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
				}
				return null;
			}

			//controller.save();

			// FSA対応 START
			if (this.requireBeneficialOwner) {
				// 実質的支配者入力
				PageReference ref = new PageReference('/apex/mpFormInfoBeneficialOwner');
				ref.setRedirect(true);
				ref.getParameters().put('id', mp.Id);
				return ref;
			} else {
				PageReference ref = new PageReference('/apex/mpFormBank');
				ref.setRedirect(true);
				ref.getParameters().put('id', mp.Id);
				return ref;
			}
			// FSA対応 END
		}

		// 3rd Step - 申し込みページ
		else if (urlValVisualforce.contains('mpFormBank') && attachment != null){

			if (OriginalStatus[0].Status__c == '申込済み' && String.isNotBlank(OriginalStatus[0].ReviewStatus__c)) {
				Error = '申込済みのため変更できません。';
				return null;
			}

			if (OriginalStatus[0].PayCyclePattern__c == 'エンプラ') {
				if (String.isBlank(mp.PayCycle__c)) {
					Error = '入金サイクルを選択してください。';
					return null;
				}
				mp.Over1Agreement__c = false;
				mp.EarlyPayoutCycle__c = false;
			} else {
				if (mp.Over1Agreement__c) {
					if (!mp.EarlyPayoutCycle__c) {
						Error = '早期振込サービス（自動）を選択してください。';
						return null;
					}
				} else {
					mp.EarlyPayoutCycle__c = false;
				}
			}

			if(OriginalStatus[0].Status__c != '口座・許認可情報入力済み' && OriginalStatus[0].Status__c != '申込済み'  ){
				mp.Status__c = '口座・許認可情報入力済み';
				mp.HiddenStatus__c = '口座・許認可情報入力済み';
				mp.BankCompleteDate__c = date.today();
			}
			//口座名義（カナ）は、先頭から30文字のみ保存→2020/02/06 60文字に縁和
			mp.AccountHolder__c = mp.AccountHolder__c.left(60);

			try {
				update mp;
			} catch (DmlException e) {

					mp.addError('システムエラー：保存されたデータに不備があります。修正後、再度フォームを開いてください');

				return null;
			}
			//controller.save();
			
			
			PageReference ref;
			if (OriginalStatus[0].AgreementType__c == '自治体契約'
				|| mp.DepositAccountType__c == '一括入金業務委託契約'
				|| mp.DepositAccountType__c == '誓約書契約'
			   // || (OriginalStatus[0].CommissionPercentage__c != null && OriginalStatus[0].CommissionPercentage__c != 1.98)
			   ) {
				ref = new PageReference('/apex/mpFormAdditionalInfo');
			} else {
				ref = new PageReference('/apex/mpAlipayForm');
			}
			ref.setRedirect(true);
			ref.getParameters().put('id', mp.Id);

			return ref;
		}
		else if (urlValVisualforce.contains('mpFormAdditionalInfo')){
			if (OriginalStatus[0].Status__c == '申込済み' && String.isNotBlank(OriginalStatus[0].ReviewStatus__c)) {
				Error = '申込済みのため変更できません。';
				return null;
			}

			try {
				update mp;
			} catch (DmlException e) {
				mp.addError('システムエラー：保存されたデータに不備があります。修正後、再度フォームを開いてください');
				return null;
			}

			PageReference ref = new PageReference('/apex/mpAlipayForm');

			ref.setRedirect(true);
			ref.getParameters().put('id', mp.Id);

			return ref;
		}
		// 2018-09-06 Alipay申込みフォーム
		else if (urlValVisualforce.contains('mpAlipayForm')){

			if (OriginalStatus[0].Status__c == '申込済み' && String.isNotBlank(OriginalStatus[0].ReviewStatus__c)) {
				Error = '申込済みのため変更できません。';
				return null;
			}

			if(attachment3.body != null){
				attachment3.ParentId = mp.Id;
				attachment3.Name =  '店舗外観写真' + attachment3.Name;
				attachment3.IsPrivate = false;
				try {
				insert attachment3;
				} catch (DMLException e) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
				return null;
				} finally {
				attachment3 = new Attachment();
				}
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Attachment uploaded successfully'));
			}

			if(attachment4.body != null){
				attachment4.ParentId = mp.Id;
				attachment4.Name =  '店舗内観写真' + attachment4.Name;
				attachment4.IsPrivate = false;
				try {
				insert attachment4;
				} catch (DMLException e) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
				return null;
				} finally {
				attachment4 = new attachment();
				}
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'attachment2 uploaded successfully'));
			}
			// スキップページ以外の場合プラン選択チェックと値設定を行う
			if(!isSkipProductForLightPlan) {
				switch on selectedPayPayMyStorePlan{
					when '1' {
						mp.mystore_kiyakudoui__c = true;
						mp.AsynchronousOnboarding__c = selectedLightplanEffectiveDate;
					}
					when '2' {
						mp.mystore_kiyakudoui__c = false;
						mp.AsynchronousOnboarding__c = '';
					}
					when else {
						Error = 'プランを選択してください。';
						return null;
					}
				}
			} else {
				// マイストアライトプラン同時申込みの加盟店による規約同意をFalse
				mp.mystore_kiyakudoui__c = false;
				// 非同期オンボーディングの値を空に設定
				mp.AsynchronousOnboarding__c = '';
			}
			//Alipayが取り扱い商品ではない場合、Alipay決済同意をFalse
			if(isAlipayNotCoveredProduct){
				mp.AlipaySettlement__c = false;
			}

			try {
				update mp;
			} catch (DmlException e) {
				mp.addError('システムエラー：保存されたデータに不備があります。修正後、再度フォームを開いてください');
				return null;
			}
			// PageReference ref = new PageReference('/apex/mpFormLastMessage');
			PageReference ref = new PageReference('/apex/mpFormKycUpload');
			ref.setRedirect(true);
			ref.getParameters().put('id', mp.Id);

			return ref;
		}

		else if (urlValVisualforce.contains('mpFormConfirmAll')) {
			if(OriginalStatus[0].Status__c != '申込済み' ) {
				// ステータスだけ更新したい
				mpOpportunity__c mpOpportunity = new mpOpportunity__c();
				mpOpportunity.Id = mp.Id;
				mpOpportunity.Status__c = '申込済み';
				mpOpportunity.HiddenStatus__c = '申込済み';
				mpOpportunity.OwnerId = UserInfo.getUserId(); //申し込み済みではない案件は、最終的に申込を行わせたユーザを所有者に変更する。
				update mpOpportunity;
			}

			PageReference ref = new PageReference('/apex/mpFormLastMessage');
			ref.setRedirect(true);
			ref.getParameters().put('id', mp.Id);
			return ref;
		}
		//アンケートを取得するために2018/05/23追加
		else if (urlValVisualforce.contains('mpFormLastMessage')){
			if(OriginalStatus[0].Status__c != '申込済み' ){
				mp.Status__c = '申込済み';
				mp.HiddenStatus__c = '申込済み';
				mp.OwnerId = UserInfo.getUserId(); //申し込み済みではない案件は、最終的に申込を行わせたユーザを所有者に変更する。
			}
			//テキストエリアのため、200文字以上は削除
			if(mp.FormSurvey__c != null){
				mp.FormSurvey__c = mp.FormSurvey__c.left(200);
			}

			try {
				update mp;
			} catch (DmlException e) {
				mp.addError('システムエラー：保存されたデータに不備があります。修正後、再度フォームを開いてください');
				return null;
			}
			PageReference ref = new PageReference('/apex/mpFormthankyou');
			ref.setRedirect(true);
			ref.getParameters().put('id', mp.Id);
			return ref;
		}
		else if (urlValVisualforce.contains('mpFormKycUpload')){
			PageReference ref = new PageReference('/apex/mpFormConfirmAll');
			ref.setRedirect(true);
			ref.getParameters().put('id', mp.Id);
			return ref;
		}
		else {
			return null;
		}
	}

	/**
	 * [FSA対応] 実質的支配者の項目を保存し、確認画面に遷移
	 */
	public PageReference saveBeneficialOwner() {

		if (this.mpBOController.questionsContainer.validate() == false) {
			return null;
		}

		this.mpBOController.save();

		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();
		PageReference ref = new PageReference('/apex/mpFormBank');
		ref.setRedirect(true);
		ref.getParameters().put('id', mp.Id);
		return ref;
	}
	
	/**
	 * [FSA対応] 実質的支配者の項目を保存し、確認画面に遷移
	 */
	public PageReference saveBeneficialOwnerFromReview() {
		string test1;
		string test2;
		string test3;
		string test4;
		string test5;
		string test6;
		string test7;
		string test8;

		if (this.mpBOController.questionsContainer.validate() == false) {
			Error = '実質的支配者のバリデーションエラー';
			return null;

		}
		
		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();
		string urlVal = Apexpages.currentPage().getUrl();
		if(urlVal.contains('mpFormInfoBeforeVisit')){
			if (mp.Over1Agreement__c) {
				if (!mp.EarlyPayoutCycle__c) {
					Error = '早期振込サービス（自動）を選択してください。';
					return null;
				}
			} else {
				mp.EarlyPayoutCycle__c = false;
			}
			
			PageId = ApexPages.currentPage().getParameters().get('id');
			List<mpOpportunity__c> OriginalStatus = [Select id,
													 LastName__c, FirstName__c, FormCustomerKanaNameLast__c, FormCustomerKanaNameFirst__c, FormCustomerBirthday__c,
													 PostalCode__c, Prefectures__c, City__c, TownName__c, FormSectionStreetNumber__c, BuildingNumber__c
													 FROM mpOpportunity__c Where id =: PageId];
			
			 if (OriginalStatus[0].LastName__c != mp.LastName__c ||
				OriginalStatus[0].FirstName__c != mp.FirstName__c ||
				OriginalStatus[0].FormCustomerKanaNameLast__c != mp.FormCustomerKanaNameLast__c ||
				OriginalStatus[0].FormCustomerKanaNameFirst__c != mp.FormCustomerKanaNameFirst__c ||
				OriginalStatus[0].FormCustomerBirthday__c != mp.FormCustomerBirthday__c ||
				OriginalStatus[0].PostalCode__c != mp.PostalCode__c ||
				OriginalStatus[0].Prefectures__c != mp.Prefectures__c ||
				OriginalStatus[0].City__c != mp.City__c ||
				OriginalStatus[0].TownName__c != mp.TownName__c ||
				OriginalStatus[0].FormSectionStreetNumber__c != mp.FormSectionStreetNumber__c ||
				OriginalStatus[0].BuildingNumber__c != mp.BuildingNumber__c
			) {
				mp.KYCHistory__c = null;
			}
		}

		try {
			update mp;
			this.mpBOController.save();
		} catch (DMLException e) {
			return null;
		}
		
		
		PageReference pg = new PageReference('/lightning/r/mpOpportunity__c/'+mp.id+'/view');
		pg.setRedirect(true);
		return pg;

	}

	public Integer additionalFileCnt1 {
		get{
			if (additionalFileCnt1 == null) {
				additionalFileCnt1 = [Select Id From Attachment Where ParentId = :PageId AND Name like '自治体契約協定書_%'].size();
			}
			return additionalFileCnt1;
		}
		set;
	}
	public Integer additionalFileCnt2 {
		get{
			if (additionalFileCnt2 == null) {
				additionalFileCnt2 = [Select Id From Attachment Where ParentId = :PageId AND Name like '一括入金業務委託契約_%'].size();
			}
			return additionalFileCnt2;
		}
		set;
	}
	public Integer additionalFileCnt3 {
		get{
			if (additionalFileCnt3 == null) {
				additionalFileCnt3 = [Select Id From Attachment Where ParentId = :PageId AND Name like '入金口座誓約書契約_%'].size();
			}
			return additionalFileCnt3;
		}
		set;
	}
	public Integer additionalFileCnt4 {
		get{
			if (additionalFileCnt4 == null) {
				additionalFileCnt4 = [Select Id From Attachment Where ParentId = :PageId AND Name like '手数料同意書_%'].size();
			}
			return additionalFileCnt4;
		}
		set;
	}
	public Boolean uploaded {
		get;set;
	}
	public Boolean uploadFinish {
		get{
			if (uploadFinish == null) {
				mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();
				uploadFinish = (
						(mp.AgreementType__c != '自治体契約' || additionalFileCnt1 > 0)
						&& (mp.DepositAccountType__c != '一括入金業務委託契約' || additionalFileCnt2 > 0)
						&& (mp.DepositAccountType__c != '誓約書契約' || additionalFileCnt3 > 0)
						//&& (mp.CommissionPercentage__c == null || mp.CommissionPercentage__c == 1.98 || additionalFileCnt4 > 0)
					);
			}
			return uploadFinish;
		}
		set;
	}

	// FSA対応
	public Boolean requireBeneficialOwner {
		get {
			mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();
			return mp.CorporateForm__c == '法人';
		}
	}

	public PageReference mpAdditionalUpload() {

		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();
		uploaded = false;
		uploadFinish = null;

		if(attachment3.body != null){
			if (mp.AgreementType__c == '自治体契約') {
				attachment3.ParentId = mp.Id;
				attachment3.Name =  '自治体契約協定書_' + Datetime.now().format('yyyy/MM/dd_HH:mm:ss') + '_' + attachment3.Name.right(200);
				attachment3.IsPrivate = false;
				try {
					insert attachment3;
					additionalFileCnt1++;
					uploaded = true;
				} catch (DMLException e) {
					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
					return null;
				} finally {
					attachment3 = new Attachment();
				}
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'attachment3 uploaded successfully'));
			} else {
				attachment3 = new Attachment();
			}
		}

		if(attachment4.body != null) {
			if (mp.DepositAccountType__c == '一括入金業務委託契約'){
				attachment4.ParentId = mp.Id;
				attachment4.Name =  '一括入金業務委託契約_' + Datetime.now().format('yyyy/MM/dd_HH:mm:ss') + '_' + attachment4.Name.right(200);
				attachment4.IsPrivate = false;
				try {
					insert attachment4;
					additionalFileCnt2++;
					uploaded = true;
				} catch (DMLException e) {
					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
					return null;
				} finally {
					attachment4 = new attachment();
				}
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'attachment4 uploaded successfully'));
			} else {
				attachment4 = new attachment();
			}
		}

		if(attachment5.body != null) {
			if (mp.DepositAccountType__c == '誓約書契約') {
				attachment5.ParentId = mp.Id;
				attachment5.Name =  '入金口座誓約書契約_' + Datetime.now().format('yyyy/MM/dd_HH:mm:ss') + '_' + attachment5.Name.right(200);
				attachment5.IsPrivate = false;
				try {
					insert attachment5;
					additionalFileCnt3++;
					uploaded = true;
				} catch (DMLException e) {
					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
					return null;
				} finally {
					attachment5 = new attachment();
				}
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'attachment5 uploaded successfully'));
			} else {
				attachment5 = new attachment();
			}
		}
		
		/*
		if(attachment6.body != null) {
			if (mp.CommissionTargetFlag__c) {
				attachment6.ParentId = mp.Id;
				attachment6.Name =  '手数料同意書_' + Datetime.now().format('yyyy/MM/dd_HH:mm:ss') + '_' + attachment6.Name.right(200);
				attachment6.IsPrivate = false;
				try {
					insert attachment6;
					additionalFileCnt4++;
					uploaded = true;
				} catch (DMLException e) {
					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
					return null;
				} finally {
					attachment6 = new attachment();
				}
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'attachment6 uploaded successfully'));
			} else {
				attachment6 = new attachment();
			}
		}*/
		return null;
	}

	public class kycFirstViewControll extends mpFormKycViewControll{
		mpForm controllClass;
		public kycFirstViewControll(mpForm controllClass, Id PageId) {
			super(PageId);
			this.controllClass = controllClass;
		}
		override public PageReference finish() {
			Savepoint sp = Database.setSavepoint();
			try {
				if ([Select Id From mpOpportunity__c Where Id = :this.PageId AND KYCHistory__c != null].size() > 0) {
					return this.controllClass.mpRedirect();
				}
				controllClass.Error = save();
				if (String.isBlank(controllClass.Error)) {
					return this.controllClass.mpRedirect();
				}
			} catch (Exception ex) {
				Database.rollback(sp);
				this.controllClass.Error = 'システムエラー：保存されたデータに不備があります。修正後、再度フォームを開いてください';
			}
			return null;
		}
		override public PageReference finishCompulsion() {
			return finish();
		}
	}
	public mpFormKycViewControll KycViewControll{
		get {
			return new kycFirstViewControll(this, PageId);
		}
	}

	@RemoteAction
	public static Map<String, String> uploadKycImage(String PageId, String KYCImageType, String SubImageFlag, String base64String){
		return mpFormKycViewControll.uploadKycImage(PageId, KYCImageType, SubImageFlag, base64String);
	}
	@RemoteAction
	public static String checkKycImageUploadFinish(String PageId, String KYCImageType){
		return mpFormKycViewControll.checkKycImageUploadFinish(PageId, KYCImageType);
	}

	public List<Decimal> getMpLngLatDefault() {
		List<Decimal> lnglat = new List<Decimal>();
		mpOpportunity__c mpGeo = [Select OgglongitudeInput__c, OgglatitudeInput__c, FormNoCorpPrefectures__c, FormNoCorpCity__c, FormNoCorpTownName__c, FormNoCorpFormSectionStreetNumber__c
		From mpOpportunity__c Where Id = :PageId Limit 1];
		if (mpGeo.OgglatitudeInput__c == 0 || mpGeo.OgglongitudeInput__c == 0 || mpGeo.OgglatitudeInput__c == null || mpGeo.OgglongitudeInput__c == null) {
			if (String.isNotBlank(mpGeo.FormNoCorpPrefectures__c) && String.isNotBlank(mpGeo.FormNoCorpCity__c)) {
				try {
					String address = ''
						 + mpGeo.FormNoCorpPrefectures__c
						 + mpGeo.FormNoCorpCity__c
						 + (String.isBlank(mpGeo.FormNoCorpTownName__c)? '' : mpGeo.FormNoCorpTownName__c)
						 + (String.isBlank(mpGeo.FormNoCorpFormSectionStreetNumber__c)? '' : mpGeo.FormNoCorpFormSectionStreetNumber__c)
					;
					Map<String, String> geoCode = mpOuterApi.getGeoCoder(address);

					if (geoCode.containsKey('error') && geoCode.get('error') == '0' && geoCode.containsKey('result') && !String.isBlank(geoCode.get('result'))) {
						List<String> geo = geoCode.get('result').split(',', 2);
						lnglat.add(Decimal.valueOf(geo.get(0)));
						lnglat.add(Decimal.valueOf(geo.get(1)));
					}
				} catch(Exception ex) {
					lnglat = new List<Decimal>();
				}
			}
			if (lnglat.isEmpty() || lnglat.size() != 2) {
				lnglat = new List<Decimal>{0, 0};
			}
		} else {
			lnglat = new List<Decimal>{mpGeo.OgglongitudeInput__c, mpGeo.OgglatitudeInput__c};
		}
		return lnglat;
	}

	private List<Decimal> getMpLngLat() {
		List<Decimal> lnglat = new List<Decimal>();
		return lnglat;
	}
	
	private void upload() {
		try{
			if(attachmentOut.Body!=null){
				attachmentOut.Name =  '店舗外観写真'  + attachmentOut.Name;
				attachmentOut.ParentId = PageId;
				attachmentOut.IsPrivate = false;
				insert attachmentOut;
			}
			if(attachmentIn.Body!=null){
				attachmentIn.Name =  '店舗内観写真'  + attachmentIn.Name;
				attachmentIn.ParentId = PageId;
				attachmentIn.IsPrivate = false;
				insert attachmentIn;
			}
			if(beforeOpenattachment1.Body!=null){
				beforeOpenattachment1.Name =  '開店前店舗資料1'  + beforeOpenattachment1.Name;
				beforeOpenattachment1.ParentId = PageId;
				beforeOpenattachment1.IsPrivate = false;
				insert beforeOpenattachment1;
			}
			if(beforeOpenattachment2.Body!=null){
				beforeOpenattachment2.Name =  '開店前店舗資料2'  + beforeOpenattachment2.Name;
				beforeOpenattachment2.ParentId = PageId;
				beforeOpenattachment2.IsPrivate = false;
				insert beforeOpenattachment2;
			}
			if(beforeOpenattachment3.Body!=null){
				beforeOpenattachment3.Name =  '開店前店舗資料3'  + beforeOpenattachment3.Name;
				beforeOpenattachment3.ParentId = PageId;
				beforeOpenattachment3.IsPrivate = false;
				insert beforeOpenattachment3;
			}
			if(beforeOpenattachment4.Body!=null){
				beforeOpenattachment4.Name =  '開店前店舗資料4'  + beforeOpenattachment4.Name;
				beforeOpenattachment4.ParentId = PageId;
				beforeOpenattachment4.IsPrivate = false;
				insert beforeOpenattachment4;
			}
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
		} finally {
			attachmentOut = new Attachment();
			attachmentIn = new Attachment();
			beforeOpenattachment1 = new Attachment();
			beforeOpenattachment2 = new Attachment();
			beforeOpenattachment3 = new Attachment();
			beforeOpenattachment4 = new Attachment();
		}

	}
	@TestVisible
	private Boolean isUploadedCheck(String target) {

			uploadedFiles = new Map<String, Boolean>();
			List<Attachment> files = [select Id, Name from Attachment where parentId =:PageId
							and (Name Like :('確認書類_%') or Name Like :('店舗%') or Name Like :('開店前店舗資料%')) order By LastModifiedDate Desc Limit 100];
			if (! files.isempty()) {
				for (Attachment file : files) {
					String prefix = file.Name.replace('確認書類_', '').replaceAll('_.*$', '');
					if (prefix.contains(target)) {
						uploadedFiles.put(target, True);
					}
				}
			}

		return uploadedFiles.containsKey(target);
	}
	
	public Boolean getIsUploadedStoreInCheck(){
		return isUploadedCheck('店舗内観写真');
	}
	public Boolean getIsUploadedStoreOutCheck(){
		return isUploadedCheck('店舗外観写真');
	}
	public Boolean getIsUploadedBeforeOpenStoreCheck(){
		return isUploadedCheck('開店前店舗資料');
	}

	/**
	 * SC申込の時
	 * 不同意の場合[自治体等への情報連携の不同意]に日付を入れる
	 */
	@RemoteAction
	public static String setInfoNonAgreement(String targetId, Boolean checkVal){
		// 更新対象レコードを取得
		mpOpportunity__c mp = [SELECT InfoAgreementCheck__c, InfoNonAgreement__c,PayPayGiftVoucherAgreement__c
								FROM mpOpportunity__c
								WHERE Id = :targetId];
		if (checkVal == false) {
			// 不同意の場合
			mp.InfoAgreementCheck__c = false;
			mp.InfoNonAgreement__c = date.today();
		} else {
			// 同意の場合
			mp.InfoAgreementCheck__c = true;
			// PayPay商品券同意もtrueの場合、自治体等への情報連携の不同意日付をnullに設定
			if (mp.PayPayGiftVoucherAgreement__c) {
				mp.InfoNonAgreement__c = null;
			}
		}

		try {
			update mp;
			return 'success';
		}catch (DmlException e) {
			return 'error';
		}
	}

	/**
	 * SC申込の時、PayPay商品券同意を設定
	 * 同意の場合:True  不同意の場合:False、[自治体等への情報連携の不同意]に日付を入れる
	 */
	@Testvisible
	@RemoteAction
	public static String setPayPayGiftVoucherAgreement(String targetId, Boolean checkVal){
		// 更新対象レコードを取得
		mpOpportunity__c mp = [SELECT InfoAgreementCheck__c, InfoNonAgreement__c,PayPayGiftVoucherAgreement__c
								FROM mpOpportunity__c
								WHERE Id = :targetId];
		if (checkVal == false) {
			// 不同意の場合
			mp.PayPayGiftVoucherAgreement__c = false;
			mp.InfoNonAgreement__c = date.today();
		} else {
			// 同意の場合
			mp.PayPayGiftVoucherAgreement__c = true;
			// 自治体等への情報連携の不同意もtrueの場合、自治体等への情報連携の不同意日付をnullに設定
			if (mp.InfoAgreementCheck__c) {
				mp.InfoNonAgreement__c = null;
			}
		}

		try {
			update mp;
			return 'success';
		}catch (DmlException e) {
			return 'error';
		}
	}
}