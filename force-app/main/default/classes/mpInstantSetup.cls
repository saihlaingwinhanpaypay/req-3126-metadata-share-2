public class mpInstantSetup {
	private ApexPages.StandardController controller;
	private mpOpportunity__c mp;
	private mpOpportunity__c originalMp;
	private Map<String, Boolean> uploadedFiles;

	public Id PageId;
	public Id OrderProId;
	public String Error {get;set;}
	public String BankError {get;set;}
	public String CorpError {get;set;}
	
	public String IncludePage {get;set;}
	public Boolean RequiredVerify {get;set;}
	public String PageIndex {get;set;}

	public String initialRepreNationality {get;set;}
	public String initialRepreNameInRomanLetters {get;set;}

	public String selectedPayPayMyStorePlan{get;set;} // 1:ライトプラン 2:制限プラン
	public String selectedLightplanEffectiveDate{get;set;}

	//FSA対応
	public mpBeneficialOwnerController mpBOController{get;set;}
	public Boolean canBeneficialOwner {get;set;}

	// 審査ステータス
	public String ReviewStatus31 = '31手動審査待ち（IS）';
	public String ReviewStatus32 = '32手動審査待ち（IS至急）';

	@TestVisible private static Boolean isDMLException = false;
	
	public mpInstantSetup(ApexPages.StandardController controller) {
		this.controller = controller;
		PageId = ApexPages.currentPage().getParameters().get('id');
		OrderProId = ApexPages.currentPage().getParameters().get('opid');
		Error='';
		BankError = '';
		CorpError = '';
		PageIndex = '';
		RequiredVerify = True;
		selectedPayPayMyStorePlan = '';
		String page = ApexPages.currentPage().getParameters().get('page');
		
		// アタックリストIDがパラメータに設定されている場合の処理
		if (!String.isBlank(String.valueOf(PageId))) {
			mp = (mpOpportunity__c) controller.getRecord();
			customerBirthYearVal = null;
			customerBirthMonthVal = null;
			customerBirthDayVal = null;

			birthYearVal = null;
			birthMonthVal = null;
			birthDayVal = null;

			uploadedFiles = null;
		}

		this.mpBOController = new mpBeneficialOwnerController(PageId);

		setOriginalMp();

		if (originalMp == null) {
			page = 'step0';
		} else {
			if (originalMp.FormCustomerBirthday__c != null) {
				List<String> birthVal = originalMp.FormCustomerBirthday__c.split('/');
				customerBirthYearVal = birthVal[0];
				customerBirthMonthVal = birthVal[1];
				customerBirthDayVal = birthVal[2];
			}
			if (originalMp.FormBirthday__c != null) {
				List<String> birthVal = originalMp.FormBirthday__c.split('/');
				birthYearVal = birthVal[0];
				birthMonthVal = birthVal[1];
				birthDayVal = birthVal[2];
			}
			//2021/10 FSA追加対応
			//step2_3→step2_4
			if (page == 'stepKyc') {
				// KYC画面は直接開かせない
				page = 'step2_4';
			}
			//2021/10 FSA追加対応
			//step2_3→step2_4
			if (page == 'step2_4' && OriginalMp.KYCHistory__c == null) {
				page = 'stepKyc';
			}
			//2021/10 FSA追加対応
			//法人ではないレコードが直接2-3を開く場合
			//2_2に遷移する
			if (page == 'step2_3' && originalMp.CorporateForm__c != '法人') {
				page = 'step2_2';
			}
			if (page == 'step3_3' && !getShowMap()) {
				page = 'step3_4';
			}
			if ((page == 'step4' || page == 'step4_1') && !getShowUpload()) {
				// アップロード書類不要の場合は飛ばす
				page = 'step4_2';
			}
			if (page == 'step4_2' && !getShowAdditionalInfo()) {
				// 追加情報不要の場合は飛ばす
				page = 'stepAlipay';
			}
			if (page == 'step4_3') {
				// 4_3までたどり着いたらAlipay
				page = 'stepAlipay';
			}
			if (page == 'stepAlipay') {
				page = 'stepKycResult';
			}
			if (page == 'confirm' && OriginalMp.KYCHistory__c == null) {
				page = 'stepKycResult';
			}
			if (originalMp.mystore_kiyakudoui__c) {
				selectedPayPayMyStorePlan = '1';
			} 
			selectedLightplanEffectiveDate = originalMp.AsynchronousOnboarding__c;
		}


		switch on page {
			when 'verify' { IncludePage = 'Verify';PageIndex='1';RequiredVerify = False;}
			when 'step1' { IncludePage = 'Step1';PageIndex='1';RequiredVerify = False;}
			when 'step2', 'step2_1' { IncludePage = 'Step2_1';PageIndex='1';}
			//2021/10 FSA追加対応
			//Step2_2をStep2_2,Step2_3として分けて対応する
			when 'step2_2' { IncludePage = 'Step2_2';PageIndex='2';}
			when 'step2_3' { IncludePage = 'Step2_3';PageIndex='3';}
			when 'stepKyc' { IncludePage = 'StepKyc';PageIndex='1';}
			when 'step2_4' { IncludePage = 'Step2_4';PageIndex='4';}
			when 'step2_5' { IncludePage = 'Step2_5';PageIndex='5';}
			when 'step2_6' { IncludePage = 'Step2_6';PageIndex='6';}
			when 'step3', 'step3_1' { IncludePage = 'Step3_1';PageIndex='1';}
			when 'step3_2' { IncludePage = 'Step3_2';PageIndex='2';}
			when 'step3_3' { IncludePage = 'Step3_3';PageIndex='3';}
			when 'step3_4' { IncludePage = 'Step3_4';PageIndex='4';}
			when 'step3_5' { IncludePage = 'Step3_5';PageIndex='5';}
			when 'step4', 'step4_1' { IncludePage = 'Step4_1';PageIndex='1';}
			when 'step4_2' { IncludePage = 'Step4_2';PageIndex='2';}
			when 'stepAlipay' {IncludePage = 'StepAlipay';PageIndex='1';}
			when 'stepKycResult' {IncludePage = 'StepKycResult';PageIndex='1';}
			when 'confirm' { IncludePage = 'StepConfirm';PageIndex='1';}
			when 'interruption' { IncludePage = 'StepInterruption';PageIndex='1';}
			when 'reviewing' { IncludePage = 'StepReviewing';PageIndex='1';}
			when 'step5', 'step5_1' { IncludePage = 'Step5_1';PageIndex='1';}
			when 'step5_2' { IncludePage = 'Step5_2';PageIndex='2';}
			when 'step5_3' { IncludePage = 'Step5_3';PageIndex='3';}
			when 'step6', 'step6_1' { IncludePage = 'Step6_1';PageIndex='1';}
			when else {
				IncludePage = 'Top';
				RequiredVerify = False;
			}
		}
	}

	// 確認コードのチェック
	public PageReference redirectcheck() {

		// サービス管理（決済事業）IDがURLにセットされている場合
		if (!String.isBlank(String.valueOf(OrderProId))) {
			if (IncludePage != 'Step5_2') {
				List<OrderProgress__c> opRec = [SELECT Id, mpOpportunityRelatedFlg__c, AccountId__c, AccountId__r.Name,
												OwnerId, OpportunityId__r.Staffid__c, OpportunityId__r.IntroducedCode__c,
												OpportunityId__r.restaurant__c FROM OrderProgress__c WHERE Id = :OrderProId];

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
						return null;
					}
					PageId = mp.Id;
				}

				// 申し込み画面へアタックリストIDを設定してリダイレクト
				PageReference ref = new PageReference('/apex/mpInstantSetup');
				ref.setRedirect(true);
				ref.getParameters().put('id', PageId);
				return ref;
				
			} else {
				// QR紐付けリカバリ専用
				PageReference ref = new PageReference('/apex/mpInstantSetupMakeQR');
				ref.setRedirect(true);
				ref.getParameters().put('id', PageId);
				return ref;
			}
		}

		if (! RequiredVerify) return null;
	
		String verify_user_param = originalMp.Parameter_Confirmation__c;
		if (verify_user_param == null
			|| (verify_user_param != makeVerifyCode(mp.Id)
				&& verify_user_param != makeVerifyCode(originalMp.yahoojp_18_Id__c)
				&& !isMagicVerifyCode(verify_user_param))) {
			// 認証失敗
			system.debug('認証失敗');
			return pageVerify();
		}

		// 確認画面の事前チェック
		//2021/10 FSA追加対応
		//step2_5→step2_6
		if (IncludePage == 'Step2_6' && originalMp.CorporateForm__c == '法人' && String.isNotBlank(originalMp.CorporateNumber__c)) {
			mpLeadScreening screening = new mpLeadScreening();
			mpLeadScreening.CompanyCheck companyCheck = new mpLeadScreening.CompanyCheck();
			Map<String, String> check = companyCheck.exec(screening.getMpOpportunity(new Set<Id>{originalMp.Id}).get(0));
			if (!check.isEmpty() &&
				(check.containsKey('0101') || check.containsKey('0102') || check.containsKey('0103') || check.containsKey('0104'))) {
				CorpError = '1';
			}
		}
		if (IncludePage == 'Step3_5' && String.isNotBlank(originalMp.AccountHolder__c)) {
			mpLeadScreening screening = new mpLeadScreening();
			mpLeadScreening.BankAccountNameCheck bankAccountNameCheck = new mpLeadScreening.BankAccountNameCheck();
			Map<String, String> check = bankAccountNameCheck.exec(screening.getMpOpportunity(new Set<Id>{originalMp.Id}).get(0));
			if (!check.isEmpty() && check.containsKey('0701')) {
				BankError = '1';
			}
		}
		return null;
	}
	
	private void setOriginalMp() {
		List<mpOpportunity__c> OriginalStatus = [Select
			id, Status__c, ReviewStatus__c, RelationStatus__c,
			CorporateForm__c, Parameter_Confirmation__c,
			CorporateNumber__c,
			FormCustomerEmail__c, FormBirthday__c,
			LastName__c, FirstName__c,
			FormCustomerKanaNameLast__c, FormCustomerKanaNameFirst__c,
			FormCustomerBirthday__c,
			PostalCode__c, Prefectures__c, City__c, TownName__c, FormSectionStreetNumber__c, BuildingNumber__c,
			RepreNationality__c, RepreNameInRomanLetters__c,
			FormStoreSales__c,MerchandiseClassification__c,
			FinancialInstitutionLabel__c, FinancialInstitutionName__c,
			ProductName__c,
			AccountHolder__c,
			BranchLabel__c, BranchName__c, MID__c, SID__c,
			Licensing_Antique__c, Licensing_TreatmentPlace__c,
			Licensing_TravelAgency__c, Licensing_Consultation__c,
			Licensing_DrivingAgency__c, Licensing_RealEstate__c,
			Licensing_SpecifiedContinuousServices__c,
			Licensing_PublicGambling__c,Licensing_PrepaidCard__c,Licensing_InsuranceBusiness__c,Licensing_TicketSales__c,
			MonthlyPaymentLimit__c, NumberOfCorrections__c,
			Ogglatitude__c, Ogglongitude__c,
			AgreementType__c, DepositAccountType__c,
			KYCHistory__c, KYCHistory__r.KYCResult__c, KYCHistory__r.KYCPriority__c, KYCHistory__r.CreatedDate, KYCHistory__r.ReviewPerson__c,
			CommissionTargetFlag__c, CommissionPercentage__c, LinePayQuestionnaire__c, PayCyclePattern__c, CommissionSpecialRate__c,
			yahoojp_18_Id__c, StoreConfirmation__c, InfoAgreementCheck__c, InfoNonAgreement__c,PayPayGiftVoucherAgreement__c,mystore_kiyakudoui__c,AsynchronousOnboarding__c
		FROM mpOpportunity__c Where id =: PageId];

		if (OriginalStatus.isEmpty()) {
			originalMp = null;
		} else {
			originalMp = OriginalStatus[0];
			initialRepreNationality = originalMp.RepreNationality__c;
			initialRepreNameInRomanLetters = originalMp.RepreNameInRomanLetters__c;
		}
	}

	public Boolean isMoneyOnlyProduct{
		get{ return (originalMp != null && originalMp.ProductName__c != null && originalMp.ProductName__c.contains('マネー限定'));}
	}
	public Boolean isBalanceOnlyProduct{
		get{ return (originalMp != null && originalMp.ProductName__c != null && originalMp.ProductName__c.contains('残高限定'));}
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

	private PageReference checkStatus() {
		setOriginalMp();
		if (OriginalMp == null) return null;
		if (OriginalMp.Status__c != '申込済み') return null;
		if (OriginalMp.RelationStatus__c == '30連携完了') return pageStep5(2); // 連携完了はQR紐付け画面へ
		if (OriginalMp.RelationStatus__c == '80連携エラー') return pageInterruption(); // 連携失敗は社内再調査の申込完了画面に遷移

		if (OriginalMp.ReviewStatus__c == '60審査可決') return pageStep5(); // 審査完了は連携画面へ

		if (OriginalMp.ReviewStatus__c == '32手動審査待ち（IS至急）') return pageReviewing();
		if (OriginalMp.ReviewStatus__c == '33手動審査（営業回答待ち）') return pageReviewing();
		if (OriginalMp.ReviewStatus__c == '33手動審査（営業回答済み）') return pageReviewing();
		if (OriginalMp.ReviewStatus__c == '62審査可決（IS）') return pageReviewing();

		// 審査待ちは社内再調査の申込完了画面に遷移
		if (String.isNotBlank(OriginalMp.ReviewStatus__c)) return pageInterruption();
		return null;
	}

	public mpInstantSetup getMpInstantSetup(){
		return this;
	}

	public boolean getIsHoujinApiMaintenance() {
		return mpOuterApi.isHoujinApiMaintenance();
	}

	public Map<String, String> getNewMerchantCampSetting() {
		return mpNewMerchantCamp.getCampaignSetting();
	}

	public boolean getShowMap() {
		if (originalMp == null || originalMp.FormStoreSales__c == '屋台・機内・社内・移動販売' || originalMp.MerchandiseClassification__c == '交通') {
			return false;
		} else {
			return true;
		}
	}

	public List<Decimal> getMpLngLatDefault() {
		List<Decimal> lnglat;
		mpOpportunity__c mpGeo = [Select OgglongitudeInput__c, OgglatitudeInput__c From mpOpportunity__c Where Id = :mp.Id Limit 1];
		if (mpGeo.OgglatitudeInput__c == 0 || mpGeo.OgglongitudeInput__c == 0 || mpGeo.OgglatitudeInput__c == null || mpGeo.OgglongitudeInput__c == null) {
			lnglat = getMpLngLat();
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
		try {
			mpOpportunity__c mpGeo = [Select FormNoCorpPrefectures__c, FormNoCorpCity__c, FormNoCorpTownName__c, FormNoCorpFormSectionStreetNumber__c
				From mpOpportunity__c
				Where Id = :mp.Id Limit 1];
			if (String.isNotBlank(mpGeo.FormNoCorpPrefectures__c) && String.isNotBlank(mpGeo.FormNoCorpCity__c)) {
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
			}
		} catch(Exception ex) {
			System.debug('緯度経度-取得失敗');
			System.debug(ex);
			lnglat = new List<Decimal>();
		}
		return lnglat;
	}
	
	public boolean uploadFlag {
		get {
			return getShowUpload();
		}
		set;
	}

	public Integer kycWaitCount {
		get {
			if (OriginalMp == null || OriginalMp.KYCHistory__c == null) return null;
			try {
				Integer kycWaitCount = [SELECT Id FROM mpHistory__c WHERE RecordType.DeveloperName = 'RecordTypeKYCReview' AND KYCResult__c = '未審査'
					AND KYCPriority__c  <= :OriginalMp.KYCHistory__r.KYCPriority__c AND CreatedDate <= :OriginalMp.KYCHistory__r.CreatedDate
					/*AND ReviewPerson__c = null*/
				].size() -1;
				return Math.max(kycWaitCount, 0);
			} catch(Exception ex) {
				return 999;
			}
		}
	}

	public boolean getShowUpload() {
		if (originalMp == null || (
				! originalMp.Licensing_Antique__c &&
				! originalMp.Licensing_TreatmentPlace__c &&
				! originalMp.Licensing_TravelAgency__c &&
				! originalMp.Licensing_Consultation__c &&
				! originalMp.Licensing_DrivingAgency__c &&
				//! originalMp.Licensing_RealEstate__c &&
				! originalMp.Licensing_SpecifiedContinuousServices__c &&
				! originalMp.Licensing_PrepaidCard__c &&
				! originalMp.Licensing_InsuranceBusiness__c &&
				! originalMp.Licensing_TicketSales__c &&
				! originalMp.Licensing_PublicGambling__c
				
				)
		) {
			return false;
		} else {
			return true;
		}
	}

	public boolean getShowAdditionalInfo() {
		if (originalMp != null && (
				originalMp.AgreementType__c == '自治体契約'
				|| originalMp.DepositAccountType__c == '一括入金業務委託契約'
				|| originalMp.DepositAccountType__c == '誓約書契約'
				// || originalMp.CommissionTargetFlag__c
				)
		) {
			return true;
		} else {
			return false;
		}
	}

	public Attachment attachment {
		get {
		if (attachment == null)
		attachment = new Attachment();
		return attachment;
		}
		set;
	}

	public String bankCode {
		get {
			if (bankCode != null) return bankCode;
			if (originalMp == null) return '';
			String label = '';
			String name = '';
			try {
				label = mp.FinancialInstitutionLabel__c;
				name = mp.FinancialInstitutionName__c;
			} catch(exception e) {
				label = originalMp.FinancialInstitutionLabel__c;
				name = originalMp.FinancialInstitutionName__c;
			}
			
			List<mpMaster__c> code = [
				Select
					BankCode__c
				From mpMaster__c
				Where
					RecordType.DeveloperName ='RecordTypeBankInfo'
					AND CanNotTransfer__c = false
					AND (
						BankLabelName__c  = :label
						AND BankSetName__c  = :name
					)
				Limit 1
			];
			if (code.isEmpty()) return '';
			return code[0].BankCode__c;
		}
		set;
	}

	public String bankBranchCode {
		get {
			if (bankBranchCode != null) return bankBranchCode;
			if (originalMp == null) return '';
			String label = '';
			String name = '';
			String branchLabel = '';
			String branchName = '';
			try {
				label = mp.FinancialInstitutionLabel__c;
				name = mp.FinancialInstitutionName__c;
				branchLabel = mp.BranchLabel__c;
				branchName = mp.BranchName__c;
			} catch(exception e) {
				label = originalMp.FinancialInstitutionLabel__c;
				name = originalMp.FinancialInstitutionName__c;
				branchLabel = originalMp.BranchLabel__c;
				branchName = originalMp.BranchName__c;
			}

			List<mpMaster__c> code = [
				Select
					BankBranchCode__c
				From mpMaster__c
				Where
					RecordType.DeveloperName ='RecordTypeBankInfo'
					AND CanNotTransfer__c = false
					AND (
						BankLabelName__c  = :label
						AND BankSetName__c  = :name
						AND BankBranchLabelName__c  = :branchLabel
						AND BankBranchSetName__c  = :branchName
					)
				Limit 1
			];
			if (code.isEmpty()) return '';
			return code[0].BankBranchCode__c;
		}
		set;
	}

	public String monthlyPaymentLimit {
		get {
			if (monthlyPaymentLimit != null) return monthlyPaymentLimit;

			List<mpMaster__c> systemSettingList = [
				Select
					MerchantSystemValue__c
				From mpMaster__c
				Where
					RecordType.DeveloperName ='MerchantSystemSetting'
					AND MerchantSystemKey__c = 'MonthlyPaymentLimit'
				Limit 1
			];
			if (systemSettingList.isEmpty()) return '';
			return systemSettingList[0].MerchantSystemValue__c;
		}
		set;
	}

	public String maxNumOfCorrections {
		get {
			if (maxNumOfCorrections != null) return maxNumOfCorrections;

			List<mpMaster__c> systemSettingList = [
				Select
					MerchantSystemValue__c
				From mpMaster__c
				Where
					RecordType.DeveloperName ='MerchantSystemSetting'
					AND MerchantSystemKey__c = 'MaxNumOfCorrections'
				Limit 1
			];
			if (systemSettingList.isEmpty()) return '0';
			return systemSettingList[0].MerchantSystemValue__c;
		}
		set;
	}
	
	
	private Boolean isUploaded(String target) {
		if (uploadedFiles == null) {
			uploadedFiles = new Map<String, Boolean>();
			List<Attachment> files = [select Id, Name from Attachment where parentId =:PageId
							and (Name Like :('確認書類_%') or Name Like :('店舗%')) order By LastModifiedDate Desc Limit 100];
			if (! files.isempty()) {
				for (Attachment file : files) {
					
					String prefix = file.Name.replace('確認書類_', '').replaceAll('_.*$', '');
					if (! uploadedFiles.containsKey(prefix)) {
						uploadedFiles.put(prefix, True);
					}
				}
			}
		}
		return uploadedFiles.containsKey(target);
	}

	private PageReference pageLayout(String page) {
		PageReference ref = new PageReference('/apex/mpInstantSetup');
		ref.getParameters().put('id', PageId);
		ref.getParameters().put('page', page);
		return ref;
	}
	private PageReference pageVerify() {
		return pageLayout('verify').setRedirect(true);
	}
	private PageReference pageStep1() {
		return pageLayout('step1').setRedirect(true);
	}
	private PageReference pageStep2() {
		return pageLayout('step2').setRedirect(true);
	}
	private PageReference pageStep2(Integer index) {
		return pageLayout('step2_'+index).setRedirect(true);
	}
	private PageReference pageStep3() {
		return pageLayout('step3').setRedirect(true);
	}
	private PageReference pageStep3(Integer index) {
		return pageLayout('step3_'+index).setRedirect(true);
	}
	private PageReference pageStep4() {
		return pageLayout('step4').setRedirect(true);
	}
	private PageReference pageStep4(Integer index) {
		return pageLayout('step4_'+index).setRedirect(true);
	}
	private PageReference pageStepAlipay() {
		return pageLayout('stepAlipay').setRedirect(true);
	}
	private PageReference pageInterruption() {
		return pageLayout('interruption').setRedirect(true);
	}
	private PageReference pageReviewing() {
		return pageLayout('reviewing').setRedirect(true);
	}
	private PageReference pageStep5() {
		return pageLayout('step5').setRedirect(true);
	}
	private PageReference pageStep5(Integer index) {
		return pageLayout('step5_'+index).setRedirect(true);
	}
	private PageReference pageStep6() {
		return pageLayout('step6').setRedirect(true);
	}

	//銀行情報格納用
	public class bankInfoModuleWrapper {
		public String value {get;set;}
		public String label {get;set;}
		public String name {get;set;}
		public bankInfoModuleWrapper(String cd, String lbl, String val){this.value = cd; this.label = lbl; this.name = val;}
	}

	//銀行検索用
	@RemoteAction
	public static List<bankInfoModuleWrapper> initSearchBank() {
		transient List<bankInfoModuleWrapper> retval = new List<bankInfoModuleWrapper>();

		retval.add(new bankInfoModuleWrapper('0001', 'みずほ銀行', 'みずほ銀行'));
		retval.add(new bankInfoModuleWrapper('0005', '三菱ＵＦＪ銀行', '三菱ＵＦＪ銀行'));
		retval.add(new bankInfoModuleWrapper('0009', '三井住友銀行','三井住友銀行'));
		retval.add(new bankInfoModuleWrapper('0010', 'りそな銀行','りそな銀行'));
		retval.add(new bankInfoModuleWrapper('0033', 'ＰａｙＰａｙ銀行','ＰａｙＰａｙ銀行'));
		retval.add(new bankInfoModuleWrapper('0036', '楽天銀行','楽天銀行'));
		retval.add(new bankInfoModuleWrapper('9900', 'ゆうちょ銀行','ゆうちょ銀行'));

		return retval;
	}

	@RemoteAction
	public static List<bankInfoModuleWrapper> SearchBank(String prmSearchTerm) {
		transient String searchTerm = '%'+prmSearchTerm+'%';
		transient List<bankInfoModuleWrapper> retval = new List<bankInfoModuleWrapper>();
		transient AggregateResult[] groupedResults = [Select BankLabelName__c, BankSetName__c, BankCode__c From mpMaster__c Where RecordType.DeveloperName ='RecordTypeBankInfo' AND CanNotTransfer__c = false 
		// AND BankCode__c != '9900'
		AND (BankLabelName__c Like: searchTerm OR BankCode__c Like: searchTerm) Group by BankCode__c, BankLabelName__c, BankSetName__c Order by BankCode__c];
		for(AggregateResult agRet : groupedResults){
			if(String.valueOf(agRet.get('BankLabelName__c')).contains(prmSearchTerm) || String.valueOf(agRet.get('BankCode__c')).contains(prmSearchTerm)){
				retval.add(new bankInfoModuleWrapper(
						String.valueOf(agRet.get('BankCode__c'))
					  , String.valueOf(agRet.get('BankLabelName__c'))
					  , String.valueOf(agRet.get('BankSetName__c'))
					)
				);
			}
		}
		return retval;
	}

	@RemoteAction
	public static List<bankInfoModuleWrapper> SearchBank_BranchOffice(String prmbankCode, String prmbankName, String prmSearchTerm){
		transient String searchTerm = '%'+prmSearchTerm+'%';
		transient List<bankInfoModuleWrapper> retval = new List<bankInfoModuleWrapper>();

		transient List<mpMaster__c> branchs = [Select BankBranchLabelName__c, BankBranchSetName__c ,BankBranchCode__c 
			From mpMaster__c
			Where RecordType.DeveloperName ='RecordTypeBankInfo' AND CanNotTransfer__c = false
			 AND BankCode__c =: prmbankCode
			 AND BankLabelName__c =: prmbankName
			 // AND BankCode__c != '9900'
			 AND (BankBranchLabelName__c Like: searchTerm OR BankBranchCode__c Like: searchTerm)
			ORDER BY BankBranchCode__c];
		for(mpMaster__c branch : branchs){
			if(branch.BankBranchLabelName__c.contains(prmSearchTerm) || branch.BankBranchCode__c.contains(prmSearchTerm)){
				retval.add(new bankInfoModuleWrapper(
						branch.BankBranchCode__c
					  , branch.BankBranchLabelName__c
					  , branch.BankBranchSetName__c
					)
				);
			}
		}
		return retval;
	}

	// 法人番号API
	@RemoteAction
	public static Map<String, String> SearchCorporateInfo(String corporateNumber){
		return mpOuterApi.SearchCorporateInfo(corporateNumber);
	}

	// 確認コード発番
	@TestVisible
	private String makeVerifyCode(String id) {
		try {
			String email = originalMp.FormCustomerEmail__c;
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

	public PageReference mpVerifyCode() {

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

		return pageStep2();
	}

	//生年月日入力 西暦和暦併記用
	public String customerBirthYearVal {get{return customerBirthYearVal == null?'0000':customerBirthYearVal;}set;}
	public String customerBirthMonthVal {get{return customerBirthMonthVal == null?'':customerBirthMonthVal;}set;}
	public String customerBirthDayVal {get{return customerBirthDayVal == null?'':customerBirthDayVal;}set;}

	public String birthYearVal {get{return birthYearVal == null?'0000':birthYearVal;}set;}
	public String birthMonthVal {get{return birthMonthVal == null?'':birthMonthVal;}set;}
	public String birthDayVal {get{return birthDayVal == null?'':birthDayVal;}set;}

	public String yearVal {get{return yearVal == null?'0000':yearVal;}set;}
	public List<SelectOption> getYearlist(){
		List<selectOption> options = new List<selectOption>();
		for (Integer i = Date.today().year()-100; i < Date.today().year()-15; i++) {
			if (i > 1988) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [平成'+ String.valueOf(i - 1988)+'] 年'));
			else if (i > 1925) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [昭和'+ String.valueOf(i - 1925)+'] 年'));
			else if (i > 1911) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [大正'+ String.valueOf(i - 1911)+'] 年'));
			else if (i > 1867) options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' [明治'+ String.valueOf(i - 1867)+'] 年'));
			else options.add(new selectOption(String.valueOf(i), String.valueOf(i)+' 年'));
			if(i == Date.today().year()-35) options.add(new selectOption('0000', '-- 年 --'));
		}
		return options;
	}
	public List<SelectOption> getMonthlist(){
		List<selectOption> options = new List<selectOption>();
		options.add(new selectOption('00', '-- 月 --'));
		for (Integer i = 0; i < 12; i++) {
			options.add(new selectOption(String.valueOf(i+1).leftPad(2, '0'), String.valueOf(i+1).leftPad(2, '0')+' 月'));
		}
		return options;
	}
	public List<SelectOption> getDaylist(){
		List<selectOption> options = new List<selectOption>();
		options.add(new selectOption('00', '-- 日 --'));
		for (Integer i = 0; i < 31; i++) {
			options.add(new selectOption(String.valueOf(i+1).leftPad(2, '0'), String.valueOf(i+1).leftPad(2, '0')+' 日'));
		}
		return options;
	}

	@TestVisible
	private boolean checkEmail(String Email) {
		if (String.isBlank(Email)) return true;

		//携帯会社のメールアドレスのバリデーション
		String CarrierMailDomain = Email.substringAfter('@');
		String DoubleCarrierMailDomain = CarrierMailDomain.substringAfter('.');

		List< mpMaster__c > checkEmail = [Select id FROM mpMaster__c Where (domain__c =: CarrierMailDomain or domain__c =: DoubleCarrierMailDomain) and RecordType.DeveloperName = 'RecordTypeCellDomain'];
		If(!checkEmail.isEmpty()){
			return false;
		}
		return true;
	}

	private mpIntroducer__c getMpIntroducer(String IntroducedCode) {
		if (String.isBlank(IntroducedCode)) return null;

		if(IntroducedCode.length() ==11&& (IntroducedCode.startsWith('090') || IntroducedCode.startsWith('080') || IntroducedCode.startsWith('070') || IntroducedCode.startsWith('060'))){
			//正しい携帯電話番号であればスルー
			return null;
		}

		if(IntroducedCode.startsWith('inv')){
			//invスタート文字はユーザ紹介でスルー
			return null;
		}

		//SBA代理店キャンペーン
	   if(IntroducedCode.length() ==10 && IntroducedCode.startsWith('SBA')){
			List<mpIntroducer__c> CodeCheck = [Select id, RelatedmpOpportunity__c FROM mpIntroducer__c Where SBACode__c =: IntroducedCode limit 1];
			If(!CodeCheck.isEmpty()){
				return CodeCheck[0];
			}
		}

		//紹介者キャンペーン
		 if (! String.isBlank(IntroducedCode)){
			List<mpIntroducer__c> CodeCheck = [Select id, RelatedmpOpportunity__c FROM mpIntroducer__c Where Code__c =: IntroducedCode limit 1];
			If(!CodeCheck.isEmpty()){
				return CodeCheck[0];
			}

			List< mpMaster__c > AssenCheck = [Select id, IntermediaryAgentCode__c FROM mpMaster__c Where RecordType.DeveloperName = 'RecordTypeMediation' and IntermediaryAgentCode__c =:IntroducedCode limit 1];
			//斡旋データのコードが一致しない場合（一致した場合は特にアクションがないためスルー）
			If(!AssenCheck.isEmpty()){
				//斡旋のデータの場合は、スルー
				return null;
			}
		 }

		Error = '入力された紹介者コードはご利用できません。正しいコードをご確認ください。';
		return null;
	}

	private void save(mpOpportunity__c mp) {
		update mp;
	}

	public PageReference mpResendMail() {
		mp.ReSendMail__c = 'Resend' + DateTime.now().format('yyyy-MM-dd HH:mm:ss');
		try {
			save(mp);
		} catch (DmlException e) {
			mp.addError('保存されたデータに不備があります。修正後、再度フォームを開いてください');
			return null;
		}

		return pageStep1();
	}

	public class kycFirstViewControll extends mpFormKycViewControll{
		mpInstantSetup controllClass;
		public kycFirstViewControll(mpInstantSetup controllClass, Id PageId) {
			super(PageId);
			this.controllClass = controllClass;
		}
		override public PageReference finish() {
			PageReference check = controllClass.checkStatus();
			if (check != null) return check;

		   controllClass.setOriginalMp();
			if (controllClass.OriginalMp.KYCHistory__c != null) {
				//2021/10 FSA追加対応
				//step2_3→step2_4
				return controllClass.pageStep2(4);
			}
			controllClass.Error = save();
			if (String.isBlank(controllClass.Error)) {
				//2021/10 FSA追加対応
				//step2_3→step2_4

				// 2024/01 mobile対応
				// モバイルアプリにてキャッシュの関係でstep2_4にリダイレクトされた際にページが遷移したことを検知できないため、
				// timestampをつけることでページ変更を検知させる。
				PageReference pr = controllClass.pageStep2(4);
				pr.getParameters().put('timestamp', String.valueOf(System.now().getTime()));
				return pr;
			}
			return null;
		}
		override public PageReference finishCompulsion() {
			return finish();
		}
	}

	public class kycReupViewControll extends mpFormKycViewControll{
		mpInstantSetup controllClass;
		public kycReupViewControll(mpInstantSetup controllClass, Id PageId) {
			super(PageId);
			this.controllClass = controllClass;
		}
		override public PageReference finish() {
			return finishCommon(controllClass.stepKycResult());
		}
		override public PageReference finishCompulsion() {
			return finishCommon(controllClass.stepKycGoConfirm());
		}
		
		private PageReference finishCommon(PageReference next) {
			PageReference check = controllClass.checkStatus();
			if (check != null) return check;

		   controllClass.setOriginalMp();
			if (controllClass.OriginalMp.KYCHistory__c != null
				&& (controllClass.OriginalMp.KYCHistory__r.KYCResult__c == '未審査' || controllClass.OriginalMp.KYCHistory__r.KYCResult__c == 'OK')) {
				return next;
			}

			controllClass.Error = save();
			if (String.isBlank(controllClass.Error)) {
				return next;
			}
			return null;
		}
	}
	public mpFormKycViewControll kycFirst{
		get {
			return new kycFirstViewControll(this, PageId);
		}
	}
	public kycReupViewControll kycReup{
		get {
			return new kycReupViewControll(this, PageId);
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
   
	public Boolean isReload{
		get{
			 return System.currentPageReference().getParameters().containsKey('reload');
		}
	}

	public PageReference stepKycResult() {
		return pageLayout('stepKycResult').setRedirect(true);
	}

	public PageReference stepKycReload() {
		PageReference ref = stepKycResult();
		ref.getParameters().put('reload', '1');
		return ref;
	}

	public PageReference stepKycGoConfirm() {
		return pageLayout('confirm').setRedirect(true);
	}

	public PageReference step1() {

		system.debug('step1処理開始');
		PageReference check = checkStatus();
		if (check != null) return check;
		
		//携帯会社のメールアドレスのバリデーション
		If (! checkEmail(mp.FormCustomerEmail__c)) {
			Error = '入力されたメールアドレスは登録に利用できません。携帯会社以外のメールアドレスを利用ください。';
			return null;
		}

		if (mp.IntroducedCode__c != null) {
			mpIntroducer__c mpIntroducer = getMpIntroducer(mp.IntroducedCode__c);
			if (Error != '') {
				// 紹介コード不正
				return null;
			}
			if (mpIntroducer != null) {
				mp.Introducedmp__c = mpIntroducer.RelatedmpOpportunity__c;
			}
		}

		if(OriginalMp.Status__c != 'Email確認済' && OriginalMp.Status__c != '店舗情報入力済' && OriginalMp.Status__c != '口座・許認可情報入力済み' && OriginalMp.Status__c != '申込済み'  ){
			mp.Bizcard__c = false; //名刺で取り込んだ情報をFalseに変更
			mp.Status__c = 'Email確認済';
			mp.HiddenStatus__c = 'Email確認済';
			mp.EmailCompleteDate__c = date.today();
			mp.password__c = mpForm.getRandomString(3);
		} else {
			mp.Status__c = OriginalMp.Status__c; // ステータス戻り防止対応
		}

		if (OriginalMp.FormCustomerEmail__c != mp.FormCustomerEmail__c) {
			mp.Parameter_Confirmation__c = '';
		}

		try {
			save(mp);
		} catch (DmlException e) {
			for (Integer i = 0; i < e.getNumDml(); i++) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
			}
			return null;
		}

		return pageStep2();
	}

	// 月間決済上限金額更新
	private mpOpportunity__c updateMonthlyPaymentLimit(mpOpportunity__c mp) {
		system.debug('updateMonthlyPaymentLimit処理開始');
		
		if (mp.CorporateForm__c != '法人' || mp.CorporateNumber__c == null) {
			return mp;
		}
		// 法人番号APIをコール
		try {
			Map<String, String> resultCorporateInfo = SearchCorporateInfo(mp.CorporateNumber__c);
			if (resultCorporateInfo.size() >= 1) {
				if (resultCorporateInfo.get('error') != '0') {
					system.debug('APIコール失敗');
					// 月間決済上限金額や法人番号指定年月日が更新できなくても、後続の審査で拾われるため何もしない
					return mp;
				}
				// 法人番号指定年月日に1年足して、現在日との日数の差を求める
				String assignmentDate = resultCorporateInfo.get('assignmentDate');
				system.debug('assignmentDate='+assignmentDate);
				// 法人番号指定年月日を更新
				mp.CorporateNumberIssueDate__c = Date.valueOf(assignmentDate);
				if (originalMp.MonthlyPaymentLimit__c == null) {
					// 月間決済上限金額を更新
					mp.MonthlyPaymentLimit__c = Decimal.valueOf(monthlyPaymentLimit);
				}
			}
		} catch (Exception e) {
			system.debug('想定外のエラーが発生（存在しない法人番号等）。法人番号='+mp.CorporateNumber__c);
			// 月間決済上限金額や法人番号指定年月日が更新できなくても、後続の審査で拾われるため何もしない
			system.debug(e.getMessage());
			return mp;
		}
		return mp;
	}

	public PageReference step2() {

		//uploadStore();
		String index = PageIndex;
		Integer next;
		next = Integer.valueOf(index) + 1;
		//2021/10 FSA追加対応
		//step2_3 && 法人ではないの場合'実質的支配者'画面を表示せずに
		//step2_4を表示させる
		if(next == 3 && originalMp.CorporateForm__c != '法人'){
			next = next + 1;
		}

		PageReference check = checkStatus();
		if (check != null) return check;
		
		Boolean resetKYC = false;
		Boolean resetCommission = false;
		Error = '';

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

		if (index == '1') {

			if (mp.AgreementType__c == '自治体契約') {
				if (String.isBlank(OriginalMp.CommissionSpecialRate__c)) {
					mp.CommissionSpecialRate__c = '1.50';
					mp.CommissionPercentage__c = null;
					mp.PayCyclePattern__c = '';
				}
			} else if (OriginalMp.CommissionSpecialRate__c == '1.50') {
				// 自治体専用のためクリアする
				mp.CommissionSpecialRate__c = '';
				mp.CommissionPercentage__c = null;
				resetCommission = true;
			} else if (OriginalMp.CommissionPercentage__c == null) {
				mp.CommissionPercentage__c = 1.98;
			}
			if (OriginalMp.CommissionTargetFlag__c && String.isBlank(OriginalMp.PayCyclePattern__c)) {
				mp.PayCyclePattern__c = 'エンプラ';
			}
			
			if (mp.PayCyclePattern__c == 'エンプラ') {
				mp.Over1Agreement__c = false;
				mp.EarlyPayoutCycle__c = false;
			}
			
			if (mp.CorporateForm__c == '個人事業主') {
				// 申込者氏名を個人事業主名として登録する
				mp.Name = mp.LastName__c + '　' + mp.FirstName__c;
				mp.NameKana__c = mp.FormCustomerKanaNameLast__c + '　' + mp.FormCustomerKanaNameFirst__c;
				mp.RepreLastName__c = mp.LastName__c;
				mp.RepreFirstName__c = mp.FirstName__c;
				mp.RepresentativeKanaNameLast__c = mp.FormCustomerKanaNameLast__c;
				mp.RepresentativeKanaNameFirst__c = mp.FormCustomerKanaNameFirst__c;
				// 法人確認方法に本人確認書類を登録する（法人種別にも個人事業主が登録される）
				mp.CorporationConfirmation__c = '本人確認書類';
				mp.CorporateNumber__c = '';
				mp.FormBirthday__c = mp.FormCustomerBirthday__c;
			} else {
				mp.CorporationConfirmation__c = '';
			}

			// 情報変更時はKYC審査やり直す
			if (OriginalMp.LastName__c != mp.LastName__c
				|| OriginalMp.FirstName__c != mp.FirstName__c
				|| OriginalMp.FormCustomerKanaNameLast__c != mp.FormCustomerKanaNameLast__c
				|| OriginalMp.FormCustomerKanaNameFirst__c != mp.FormCustomerKanaNameFirst__c
				|| OriginalMp.FormCustomerBirthday__c != mp.FormCustomerBirthday__c
			) {
				// KYC審査やり直し
				resetKYC = true;
			}
		} else if (index == '2') {
			if (OriginalMp.CorporateForm__c == '個人事業主') {
				// 情報変更時はKYC審査やり直す(カナの変更だけならリセットしない)
				if (OriginalMp.PostalCode__c != mp.PostalCode__c
					|| OriginalMp.Prefectures__c != mp.Prefectures__c
					|| OriginalMp.City__c != mp.City__c
					|| OriginalMp.TownName__c != mp.TownName__c
					|| OriginalMp.FormSectionStreetNumber__c != mp.FormSectionStreetNumber__c
					|| OriginalMp.BuildingNumber__c != mp.BuildingNumber__c
				) {
					// KYC審査やり直し
					resetKYC = true;
				}
			}
		//2021/10 FSA追加対応
		//index3→index4
		} else if (index == '4') {
			if((!getIsUploadedStoreOutCheck() && attachmentOut.Body == null)
			   || (!getIsUploadedStoreInCheck() && attachmentIn.Body == null)) {
				Error = '店舗画像が添付されていません。';
				attachmentOut = new Attachment();
				attachmentIn = new Attachment();
				return null;
			}
			upload();
		//2021/10 FSA追加対応
		//index4→index5
		} else if (index == '5') {
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
			//Alipayが取り扱い商品ではない場合、Alipay決済同意をFalse
			if(isAlipayNotCoveredProduct) {
				mp.AlipaySettlement__c = false;
			}

		//2021/10 FSA追加対応
		//index5→index6
		} else if (index == '6') {
			// 確認画面からの遷移
			
			mp = updateMonthlyPaymentLimit(mp);
			
			if(OriginalMp.Status__c != '店舗情報入力済' && OriginalMp.Status__c != '口座・許認可情報入力済み' && OriginalMp.Status__c != '申込済み'  ){
				mp.Status__c = '店舗情報入力済';
				mp.HiddenStatus__c = '店舗情報入力済';
				mp.ShopInfoCompleteDate__c = date.today();
			} else {
				mp.Status__c = OriginalMp.Status__c; // ステータス戻り防止対応
			}

			try {
				save(mp);
			} catch (DmlException e) {
				for (Integer i = 0; i < e.getNumDml(); i++) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
				}
				return null;
			}
			return pageStep3();
		}

		try {
			if (resetKYC) {
				if (OriginalMp.KYCHistory__c != null && OriginalMp.KYCHistory__r.ReviewPerson__c != null) {
					// 審査開始してるならリセット
					mp.KYCHistory__c = null;
				}
			}
			save(mp);
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
			if (index == '2' && OriginalMp.CorporateForm__c == '個人事業主') {
				this.mpBOController.removeBeneficialOwner();
			}
			if (resetKYC) {
				/* 機微情報の確認が必要なので確認不要にはしない
				if (OriginalMp.KYCHistory__c != null && OriginalMp.KYCHistory__r.KYCResult__c == '未審査') {
					//　審査前だったら確認不要にする
					update new mpHistory__c(
						Id = OriginalMp.KYCHistory__r.Id,
						KYCResult__c = '確認不要'
					);
				}
				*/
				OriginalMp.KYCHistory__c = null;
			}
		} catch (DmlException e) {
			Error = '入力されたデータに不備があります。エラー内容を確認してください。';
			for (Integer i = 0; i < e.getNumDml(); i++) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
			}
			return null;
		}

		//2021/10 FSA追加対応
		//実質的支配者の画面分けにより、以下の処理が不要のため、コメントアウト
		/*
		if (index == '3') {
			if (OriginalMp.CorporateForm__c == '法人') {
				canBeneficialOwner = true;
				// oncompleteの処理があるのでnullを返す
				return null;
			}
		}
		*/

		return pageStep2(next);
	}

	public PageReference step2back() {
		String index = System.currentPageReference().getParameters().get('backIndex');
		if (String.isBlank(index) || ! Pattern.matches('^[0-9]$', index) || Integer.valueOf(index) >= 7) {
			index = '1';
		}else if(index == '3' && originalMp.CorporateForm__c != '法人'){
			//2021/10 FSA追加対応
			//step2_3 && 法人ではないの場合'実質的支配者'画面を表示せずに
			//step2_2を表示させる
			index = '2';
		}
		return pageStep2(Integer.valueOf(index));
	}

	/**
	 * 実質的支配者を保存する。
	 * 原則step2_2からの呼び出しを想定している。
	 * 2021/10 FSA追加対応
	 * 実質的支配者の画面分けにより、実質的支配者の画面(Step2-3)で「次へ」ボタンを押下すると
	 * 以下のメソッドが呼ばれるように修正を行う
	 */

	public PageReference saveBeneficialOwner() {
		System.debug('Error: ' + Error);
		//2021/10 FSA追加対応
		//開始時エラーチェック不要のため、コメントアウト
		/*if (String.isNotBlank(Error)) {
			return null;
		}*/
		String index = PageIndex;
		Integer next;
		next = Integer.valueOf(index) + 1;
		
		system.debug('saveBeneficialOwner処理開始 index='+index);
		PageReference check = checkStatus();
		if (check != null) return check;

		// なくても良いIF文だが不要な呼び出しを避けるために記述
		//2021/10 FSA追加対応
		//saveBeneficialOwner()は実質的支配者画面でのみ呼ばれるようになったため、
		//以下の分岐が不要になる
		//if (index == '3' || OriginalMp.CorporateForm__c == '法人') {
			
			if (this.mpBOController.questionsContainer.validate()) {
				System.debug('実質的支配者: validate ok');
				try {
					this.mpBOController.save();
				} catch (DmlException e) {
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
					for (Integer i = 0; i < e.getNumDml(); i++) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
					}
					return null;
				}
			} else {
				System.debug('実質的支配者: validate ng');
				Error = '入力されたデータに不備があります。エラー内容を確認してください。';
				return null;
			}

		//}

		return pageStep2(next);
	}

	public PageReference step3() {
		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();

		String index = PageIndex;
		Integer next;
		
		system.debug('step3処理開始 index='+index);
		PageReference check = checkStatus();
		if (check != null) return check;

		if (String.isBlank(index) || ! Pattern.matches('^[0-9]$', index) || Integer.valueOf(index) > 5) {
			return null;
		}
		next = Integer.valueOf(index) + 1;
		Error = '';
		BankError = '';
		if (index == '1') {
			// 必須チェック
			if (mp.FinancialInstitutionLabel__c == 'ゆうちょ銀行') {
				if (String.isBlank(mp.JapanPostBankSymbol__c) || mp.JapanPostBankSymbol__c.length() != 5) {
					mp.JapanPostBankSymbol__c.addError('5桁の数字を入力して下さい。');
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
				} else if (! Pattern.matches('^1[0-9]+0$', mp.JapanPostBankSymbol__c)){
					mp.JapanPostBankSymbol__c.addError('1始まり、0終わりの記号を入力して下さい。');
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
				}
				if (String.isBlank(mp.JapanPostBankNumber__c) || mp.JapanPostBankNumber__c.length() > 8) {
					mp.JapanPostBankNumber__c.addError('8桁以内の数字を入力して下さい。');
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
				} else if(! Pattern.matches('^[0-9]+1$', mp.JapanPostBankNumber__c)){
					mp.JapanPostBankNumber__c.addError('1終わりの番号を入力して下さい。');
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
				}
			} else {
				if (String.isBlank(mp.BranchLabel__c)) {
					BankError = '支店名を選択してください。';
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
				}
				if (String.isBlank(mp.AccountType__c)) {
					mp.AccountType__c.addError('入力して下さい。');
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
				}
				if (String.isBlank(mp.AccountNumber__c)) {
					mp.AccountNumber__c.addError('入力して下さい。');
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
				}
			}
			if (Error != '') return null;

			if (mp.FinancialInstitutionLabel__c == 'ゆうちょ銀行') {
				String BranchCode = mp.JapanPostBankSymbol__c.substring(1, 3) + '8';
				List<mpMaster__c> code = [
					Select
						BankBranchLabelName__c, BankBranchSetName__c
					From mpMaster__c
					Where
						RecordType.DeveloperName ='RecordTypeBankInfo'
						AND CanNotTransfer__c = false
						AND (
							BankLabelName__c  = 'ゆうちょ銀行'
							AND BankSetName__c  = 'ゆうちょ銀行'
							AND BankBranchCode__c  = :BranchCode
						)
					Limit 1
				];
				if (code.isEmpty()) {
					mp.JapanPostBankSymbol__c.addError('入力いただいた記号では店番の存在が確認できませんでした。<br>記号が正しく入力されているか、再度ご確認ください。', false);
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
					return null;
				}
				mp.BranchLabel__c = code[0].BankBranchLabelName__c;
				mp.BranchName__c = code[0].BankBranchSetName__c;
			} else {
				// 金融機関選択画面からの遷移
				AggregateResult[] ARs = [
					Select
						COUNT(Id) bankCount
					From mpMaster__c
					Where
						RecordType.DeveloperName ='RecordTypeBankInfo'
						AND CanNotTransfer__c = false
						AND (
							BankLabelName__c  = :mp.FinancialInstitutionLabel__c
							AND BankSetName__c  = :mp.FinancialInstitutionName__c
							AND BankBranchLabelName__c  = :mp.BranchLabel__c
							AND BankBranchSetName__c  = :mp.BranchName__c
						)
				];
				If(ARs == null || ARs[0].get('bankCount') == 0){
					BankError = '入力いただいた金融機関・支店の存在が確認できませんでした。<br>金融機関名と支店名が正式名称で入力されているか、再度ご確認ください。';
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
					return null;
				}
			}
			if (mp.FinancialInstitutionLabel__c == 'ゆうちょ銀行') {
				mp.JapanPostBankFlag__c = True;
				mp.AccountType__c = '普通';
				mp.AccountNumber__c = '';
			} else {
				mp.JapanPostBankFlag__c = False;
				mp.JapanPostBankSymbol__c = '';
				mp.JapanPostBankNumber__c = '';
			}

			//口座名義（カナ）は、先頭から30文字のみ保存
			mp.AccountHolder__c = mp.AccountHolder__c.left(30);

		} else if (index == '2') {
			// 入金サイクル同意
			if (OriginalMp.PayCyclePattern__c == 'エンプラ') {
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
		} else if (index == '3') {
			// 地図選択画面
		} else if (index == '4') {
			// 許認可のチェックボックス画面
			// スキップページ以外の場合プラン選択チェックと値設定を行う
			if (!isSkipProductForLightPlan) {
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
		} else if (index == '5') {
			// 確認画面
		}

		try {
			save(mp);
		} catch (DmlException e) {
			Error = '入力されたデータに不備があります。エラー内容を確認してください。';
			for (Integer i = 0; i < e.getNumDml(); i++) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
			}
			return null;
		}
		if (index == '5') {
			// ファイルアップロードへ
			if(!getShowUpload() && OriginalMp.Status__c != '口座・許認可情報入力済み' && OriginalMp.Status__c != '申込済み'  ) {
				mp.Status__c = '口座・許認可情報入力済み';
				mp.HiddenStatus__c = '口座・許認可情報入力済み';
				mp.BankCompleteDate__c = date.today();
				update mp;
			} else {
				mp.Status__c = OriginalMp.Status__c; // ステータス戻り防止対応
			}
			return pageStep4();
		} else {
			return pageStep3(next);
		}
	}

	public PageReference step3back() {
		String index = System.currentPageReference().getParameters().get('backIndex');
		if (String.isBlank(index) || ! Pattern.matches('^[0-9]$', index) || Integer.valueOf(index) >= 6) {
			index = '1';
		}
		return pageStep3(Integer.valueOf(index));
	}

	public PageReference stepAlipayCheck() {
		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();

		PageReference check = checkStatus();
		if (check != null) return check;
		Error = '';

		try {
			save(mp);
		} catch (DmlException e) {
			Error = '入力されたデータに不備があります。エラー内容を確認してください。';
			for (Integer i = 0; i < e.getNumDml(); i++) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
			}
			return null;
		}
		if (mp.AlipaySettlement__c) {
			return pageStepAlipay();
		} else {
			return stepKycResult();
		}
	}

	public PageReference stepAlipay() {
		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();

		PageReference check = checkStatus();
		if (check != null) return check;

		Error = '';
		if (mp.AlipaySettlement__c) {
			if ([Select Id From Attachment Where parentId = :mp.Id AND Name like  :('店舗内観%') AND BodyLength > 0].size() == 0) {
				Error = '店舗内観写真を登録してください。';
				return null;
			}
			if ([Select Id From Attachment Where parentId = :mp.Id AND Name like  :('店舗外観%') AND BodyLength > 0].size() == 0) {
				Error = '店舗外観写真を登録してください。';
				return null;
			}
		}
		try {
			save(mp);
		} catch (DmlException e) {
			Error = '入力されたデータに不備があります。エラー内容を確認してください。';
			for (Integer i = 0; i < e.getNumDml(); i++) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
			}
			return null;
		}
		return stepKycResult();
	}

	public PageReference step4() {
		String index = PageIndex;
		Integer next;
		next = Integer.valueOf(index) + 1;
		Error = '';
		setOriginalMp();

		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();

		system.debug('step4処理開始 index='+index);

		if (index == '1') {
			if(OriginalMp.Status__c != '口座・許認可情報入力済み' && OriginalMp.Status__c != '申込済み'  ) {
				mp.Status__c = '口座・許認可情報入力済み';
				mp.HiddenStatus__c = '口座・許認可情報入力済み';
				mp.BankCompleteDate__c = date.today();
			} else {
				mp.Status__c = OriginalMp.Status__c; // ステータス戻り防止対応
			}
		}

		try {
			save(mp);
		} catch (DmlException e) {
			Error = '入力されたデータに不備があります。エラー内容を確認してください。';
			for (Integer i = 0; i < e.getNumDml(); i++) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
			}
			return null;
		}
		return pageStep4(next);
	}

	public PageReference confirm() {

		PageReference check = checkStatus();
		if (check != null) return check;

		if(OriginalMp.Status__c != '申込済み'  ){
			if (OriginalMp.KYCHistory__c == null) {
				return stepKycResult();
			}
			mp.Status__c = '申込済み';
			mp.HiddenStatus__c = '申込済み';
			mp.CompleteDateTime__c = date.today();
			mp.OwnerId = UserInfo.getUserId(); //最終的に申込を行わせたユーザを所有者に変更する（2019-09-04追記）
			mp.ExtendFormType__c = '1';
		} else {
			if (String.isNotBlank(OriginalMp.ReviewStatus__c)) {
				return pageInterruption(); // 審査待ち画面へ
			}
			mp.Status__c = OriginalMp.Status__c; // ステータス戻り防止対応
		}
		
		// APIコールが必要な処理は先に実行する
		List<Decimal> geoCode = new List<Decimal>();
		if (OriginalMp.Ogglatitude__c == null && OriginalMp.Ogglongitude__c == null) {
			geoCode = getMpLngLat();
		}

		// 審査APIをコールし、ワーニングの有無をチェック
		mpLeadScreening screeningClass = new mpLeadScreening();
		Map<String, String> result = screeningClass.execSmartStart(PageId);
		list<String> logSavingValues = new List<String>();
        if (!result.isEmpty()) {
            for (String key : result.keySet()) {
                if (key.contains('ログ')) {
                    String logValue = result.get(key);
                    logSavingValues.add(logValue);
                    result.remove(key);
                }
            }
            
            if (result.containsKey('getWarningResult')) {
                result.remove('getWarningResult');
            }
        }
		Logger logger = new Logger();

		if(logSavingValues!=null){
			for(String jsonValue : logSavingValues){
				Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonValue);
				String businessType = (String) jsonMap.get('businessType');
				String errorBody = (String) jsonMap.get('error_body');
				String mpId = (String) jsonMap.get('id');
				String errorParam = (String) jsonMap.get('error_param');
				String errorStatus = (String) jsonMap.get('error_status');
				logger.error(
					'反社チェックAPI' + '(' + businessType + ')', 
					'\n▼エラー情報\n' + errorBody + 
					'\n▼失敗したレコードの審査ID\n' + mpId + 
					'\n▼失敗したレコードのパラメータ\n' + errorParam + 
					'\n▼httpステータス\n' + errorStatus, 
					mpId, 
					false
				);
			}
		}
		// ワーニングコードを全て取得
		Set<String> codeList = new Set<String>();
		for (String sKey : result.keySet()) {
			System.debug(sKey);
			codeList.add(sKey);
		}

		List<mpMaster__c> unsupportedWarningList = [Select Id, WarningCode__c FROM mpMaster__c 
													Where (WarningCode__c  IN :codeList) AND RecordType.DeveloperName = 'WarningCode'
													AND WarningUnsupportedForSc__c = true];

		Boolean existUnsupported = !unsupportedWarningList.isEmpty();
		mp.ReviewStatus__c = '14重複チェック依頼';
		logger.saveAll();
		try {
			save(mp);
			if (String.isNotBlank([Select OldReviewResult__c From mpOpportunity__c Where Id = :mp.Id Limit 1].OldReviewResult__c)) {

				mp.ReviewStatus__c = '50再審査';
				save(mp);
				// 再審査にまわるため、ここでは審査ステータスの変更を行わない

				// 審査センターの営業時間外　なら後日
				// 仮/本審査はmpLeadScreeningBatch.clsで入れるのでここでチェックしない
				if ( !Test.isRunningTest() && !getIsReviewCenterOpen() ){
					// 社内再調査の申込完了画面（後日審査画面）に遷移
					return pageInterruption();
				}else{
					// 1801ワーニングが再審査後に出るはず
					// この時点で他のワーニング未サポート(SC向け)がない　もしくは
					// 他のワーニング未サポート(SC向け)が特定のワーニングのみか？　で判定する
					if( !existUnsupported
						|| ( existUnsupported 
							&& isChangeReviewStatusTo32(unsupportedWarningList) )
					){
						// 当日審査画面に遷移
						return pageReviewing();
					}else{
						// 社内再調査の申込完了画面（後日審査画面）に遷移
						return pageInterruption();
					}
				}
				
			} else {
				mp.ReviewStatus__c = null;
			}
		} catch(Exception e) {
			// リカバリとして審査ステータスを戻しておく
			try {
				mp.ReviewStatus__c = null;
				save(mp);
			} catch(Exception ex) {}
			// 社内再調査の申込完了画面に遷移
			return pageInterruption();
		}

		//Set<String> codeList = new Set<String>();
		if (result.isEmpty()) {
			system.debug('ワーニングなし');
			// 自動審査結果を設定
			mp.ReviewAutoResult__c = '';
			mp.ReviewAutoCodeList__c = '';
			mp.ReviewAutoStartDate__c = datetime.now();
		} else {
			system.debug('ワーニングあり');
			
			String reviewAutoResult = '';
			for (String sKey : codeList) {
				// 自動審査結果用メッセージを設定
				reviewAutoResult += sKey+','+result.get(sKey)+';'+'\r\n';
			}
			
			// 自動審査結果を設定
			mp.ReviewAutoResult__c = reviewAutoResult;
			mp.ReviewAutoCodeList__c = String.join(new List<String>(codeList), ',');
			mp.ReviewAutoStartDate__c = datetime.now();

			MpHistory__c mpHistory = new MpHistory__c();
			mpHistory.mpRelation__c = mp.id;
			mpHistory.RecordTypeId = '0122x000000ooUMAAY';
			mpHistory.Comment__c = mp.ReviewAutoResult__c;
			insert mpHistory;
			
			if (originalMp.NumberOfCorrections__c == null) {
				system.debug('originalMp.NumberOfCorrections__cを0で初期化');
				originalMp.NumberOfCorrections__c = 0;
			}
			
			Boolean existSupported = ![Select Id FROM mpMaster__c
									   Where (WarningCode__c  IN :codeList) AND RecordType.DeveloperName = 'WarningCode'
									   AND WarningUnsupportedForSc__c = false AND MainExaminationFlag__c = false].isEmpty();

			if (existUnsupported || (existSupported && originalMp.NumberOfCorrections__c >= Decimal.valueOf(maxNumOfCorrections))) {
				System.debug('未サポートのワーニングがあります。');

				if( existUnsupported 
					&& isChangeReviewStatusTo32(unsupportedWarningList) 
					&& getIsReviewCenterOpen() 
					&& !String.isBlank(PayPayReviewOparationExtendComponent.startReview(mp.Id))
				){
					mp.ReviewStatus__c = ReviewStatus32;
				}else{                
					mp.ReviewStatus__c = ReviewStatus31;
				}
				mp.RelationStatus__c = '';

				//審査対象日時　設定
				upsertExaminationDateTime(mp.Id);

				try {
					save(mp);
				} catch (DmlException e) {
					Error = 'データの登録でエラーが発生しました。再度お試しください。';
					for (Integer i = 0; i < e.getNumDml(); i++) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
					}
					return null;
				}

				if(mp.ReviewStatus__c == ReviewStatus32) {
					return pageReviewing();
				} else {
					// 社内再調査の申込完了画面に遷移
					return pageInterruption();
				}
			} else if (existSupported) {
				System.debug('一次審査対象のワーニングあり');
				Set<String> warningMessageMap = new Set<String>();
				for (mpMaster__c master : [Select WarningMessageForSc__c
										   FROM mpMaster__c Where (WarningCode__c  IN :codeList)
										   AND RecordType.DeveloperName = 'WarningCode'
										   AND WarningUnsupportedForSc__c = false AND MainExaminationFlag__c = false]
				) {
					if (!String.isBlank(master.WarningMessageForSc__c)) {
						warningMessageMap.add(master.WarningMessageForSc__c.trim());
					}
				}
				mp.NumberOfCorrections__c = ++originalMp.NumberOfCorrections__c;
				Error = '登録内容に不備があります。内容を確認してください。';
				if (!warningMessageMap.isEmpty()) {
					Error = Error + '<br/>・' + String.join(new List<String>(warningMessageMap), '<br/>・');
				}
				
				try {
					save(mp);
				} catch (DmlException e) {
					Error = '入力されたデータに不備があります。エラー内容を確認してください。';
					for (Integer i = 0; i < e.getNumDml(); i++) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(i)));
					}
					return null;
				}
				return null;
			}
		}
		system.debug('一次審査対象のワーニングなし');

		if (OriginalMp.Ogglatitude__c == null && OriginalMp.Ogglongitude__c == null) {
			try {
				if (!geoCode.isEmpty() && geoCode.size() == 2 && geoCode.get(0) > 0) {
					mp.OgglongitudeInput__c = geoCode.get(0);
					mp.OgglatitudeInput__c = geoCode.get(1);
				}
			} catch(Exception ex) {
				System.debug('緯度経度-取得失敗');
				System.debug(ex);
			}
		}

		mp.PreReviewStatus__c = '可決';
		
		//一次審査可決日および審査担当者初回着手日　設定
		upsertFirstReviewPassedDate(mp.Id);

		if (!getIsReviewCenterOpen() || String.isBlank(PayPayReviewOparationExtendComponent.startReview(mp.Id))) {
			mp.ReviewStatus__c = ReviewStatus31;
			mp.RelationStatus__c = '';

			//審査対象日時　設定
			upsertExaminationDateTime(mp.Id);
		} else {
			mp.ReviewStatus__c = ReviewStatus32;
			mp.RelationStatus__c = '';

			//審査対象日時　設定
			upsertExaminationDateTime(mp.Id);
		}
			
		try {
			save(mp);
		} catch (DmlException e) {
			return pageInterruption();
		}
		if (mp.ReviewStatus__c == ReviewStatus32) {
			return pageReviewing();
		} else {
			return pageInterruption();
		}
	}

	private Boolean isChangeReviewStatusTo32(List<mpMaster__c> unsupportedWarningList){
		List<String> warningcodesTo32 = new List<String>{'0231','0261','0267','1101'};

		for( mpMaster__c master : unsupportedWarningList){
			if( !warningcodesTo32.contains(master.WarningCode__c)){
				return false;
			}
		}
		return true;
	}

	public PageReference stepReviewingReload() {
		PageReference check = checkStatus();
		if (check == null) return pageInterruption();
		if (OriginalMp.ReviewStatus__c == '62審査可決（IS）') {
			return stepReviewingFinish();
		}
		return check;
	}

	public PageReference stepReviewingRestart() {
		PageReference check = checkStatus();
		if (check == null) return pageInterruption();
		if (!check.getUrl().contains('reviewing')) return check;

		try {
			if (
				((OriginalMp.StoreConfirmation__c == '確認中（店舗外観）' || OriginalMp.StoreConfirmation__c == '確認中（店舗外観・内観）')
				&& attachmentOut.Body == null)
				||
				((OriginalMp.StoreConfirmation__c == '確認中（店舗内観）' || OriginalMp.StoreConfirmation__c == '確認中（店舗外観・内観）')
				 && attachmentIn.Body == null)
			   ) {
				Error = '店舗画像が添付されていません。';
				attachmentOut = new Attachment();
				attachmentIn = new Attachment();
				return null;
			}
			upload();
			mp.ReviewStatus__c = '33手動審査（営業回答済み）';
			save(mp);
		} catch(exception ex) {
			return pageInterruption();
		}
		return pageReviewing();
	}

	private PageReference stepReviewingFinish() {
		mpLeadScreening screeningClass = new mpLeadScreening();
		Map<String, String> result = screeningClass.execSmartStart(PageId);
        list<String> logSavingValues = new List<String>();
		if (!result.isEmpty()){
			for (String key : result.keySet()) {
				if (key.contains('ログ')) {
					String logValue = result.get(key);
					logSavingValues.add(logValue);
					result.remove(key);
				}
			}
			
			if (result.containsKey('getWarningResult')) {
				result.remove('getWarningResult');
			}
		}
        
        Logger logger = new Logger();

		if(logSavingValues!=null){
			for(String jsonValue : logSavingValues){
				Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonValue);
				String businessType = (String) jsonMap.get('businessType');
				String errorBody = (String) jsonMap.get('error_body');
				String mpId = (String) jsonMap.get('id');
				String errorParam = (String) jsonMap.get('error_param');
				String errorStatus = (String) jsonMap.get('error_status');
				logger.error(
					'反社チェックAPI' + '(' + businessType + ')', 
					'\n▼エラー情報\n' + errorBody + 
					'\n▼失敗したレコードの審査ID\n' + mpId + 
					'\n▼失敗したレコードのパラメータ\n' + errorParam + 
					'\n▼httpステータス\n' + errorStatus, 
					mpId, 
					false
				);
			}
		}
        logger.saveAll();
		try {
			mpOpportunity__c mp = new mpOpportunity__c(
				Id = OriginalMp.Id
			);
			if (result.isEmpty() || isChangeReviewStatusTo60(result)) {
				String debugStr = result.isEmpty() ? 'ワーニングなし' : 'ワーニングが' + String.join(warningcodesTo60,',') +'のみ';
				system.debug(debugStr);
				// 自動審査結果を設定
				mp.ReviewAutoResult__c = '';
				mp.ReviewAutoCodeList__c = '';
				mp.ReviewAutoStartDate__c = datetime.now();
				mp.ReviewStatus__c = '60審査可決';
				mp.RelationStatus__c = '20連携処理中';
				update mp;
				return pageStep5();
			} else {
				system.debug('ワーニングあり');
				
				Set<String> codeList = new Set<String>();
				String reviewAutoResult = '';
				// ワーニングコードを全て取得
				for (String sKey : result.keySet()) {
					System.debug(sKey);
					codeList.add(sKey);
					// 自動審査結果用メッセージを設定
					reviewAutoResult += sKey+','+result.get(sKey)+';'+'\r\n';
				}
				// 自動審査結果を設定
				mp.ReviewAutoResult__c = reviewAutoResult;
				mp.ReviewAutoCodeList__c = String.join(new List<String>(codeList), ',');
				mp.ReviewAutoStartDate__c = datetime.now();
				mp.ReviewStatus__c = '40手動審査中';
				mp.RelationStatus__c = '';
				
				MpHistory__c mpHistory = new MpHistory__c();
				mpHistory.mpRelation__c = mp.id;
				mpHistory.RecordTypeId = '0122x000000ooUMAAY';
				mpHistory.Comment__c = mp.ReviewAutoResult__c;
				insert mpHistory;

				update mp;
			}
		} catch(Exception ex) {
			System.debug(ex);
		}
		return pageInterruption();
	}

	private List<String> warningcodesTo60 = new List<String>{'1801','0231','0261','0267'};
	
	private Boolean isChangeReviewStatusTo60(Map<String, String> warningResult){

		for( String warning : warningResult.keySet()){
			if( !warningcodesTo60.contains(warning)){
				return false;
			}
		}
		return true;
	}

	public PageReference stepReviewingInterruption() {
		setOriginalMp();
		if (OriginalMp != null && OriginalMp.Status__c == '申込済み') {
			try {
				switch on (OriginalMp.ReviewStatus__c) {
					when '32手動審査待ち（IS至急）', '33手動審査（営業回答済み）' {
						update new mpOpportunity__c(
							Id = OriginalMp.Id,
							ReviewStatus__c = '40手動審査中'
						);
					}
					when '33手動審査（営業回答待ち）' {
						update new mpOpportunity__c(
							Id = OriginalMp.Id,
							ReviewStatus__c = '40手動審査中',
							ReviewToBusinessStatus__c = '要確認【営業】'
						);
					}
					when '62審査可決（IS）' {
						update new mpOpportunity__c(
							Id = OriginalMp.Id,
							ReviewStatus__c = '50再審査'
						);
					}
				}
			} catch(Exception ex) {
				System.debug(ex);
			}
		}
		return pageInterruption();        
	}
	
	private static String checkStr(String str) {
		return String.isBlank(str) ? '' : str;
	}
	
	public PageReference step4back() {
		String index = System.currentPageReference().getParameters().get('backIndex');
		if (String.isBlank(index) || ! Pattern.matches('^[0-9]$', index) || Integer.valueOf(index) >= 3) {
			index = '1';
		}
		return pageStep4(Integer.valueOf(index));
	}
	
	public PageReference step5() {
		String index = PageIndex;
		Integer next;
		next = Integer.valueOf(index) + 1;
		setOriginalMp();

		mpOpportunity__c mp = (mpOpportunity__c) controller.getRecord();
		Error = '';
		
		system.debug('step5処理開始 index='+index);        
		PageReference refNext = null;
		if (OriginalMp.ReviewStatus__c != '60審査可決' || OriginalMp.RelationStatus__c == '80連携エラー') {
			return pageInterruption();
		}

		if (index == '1') {
			// 処理画面からの遷移
			if (OriginalMp.RelationStatus__c == '30連携完了') return pageStep5(next);
			if (OriginalMp.RelationStatus__c != '20連携処理中') return pageInterruption();
			if (OriginalMp.CommissionPercentage__c == null) {
				update new mpOpportunity__c(
					Id = OriginalMp.Id,
					RelationStatus__c = '00連携保留'
				);
				return pageInterruption();
			}

			// 連携APIをコールし、MID/SIDを保存する
			List<Map<String, String>> result = mpOuterApi.executeMigration(PageId);
			if (result.size() >= 1) {
				if (result.get(0).get('error') != null) {
					system.debug('APIコール失敗');
					Error = '通信中にエラーが発生しました。しばらく経ってからもう一度お試しください。';
					mp.RelationStatus__c = '80連携エラー';
					// 連携失敗は社内再調査の申込完了画面に遷移
					refNext = pageInterruption();

				} else {
					// APIレスポンスを連携結果に設定
					mp.RelationResult__c = result.get(0).get('body');
					
					if (result.get(1).get('resultStatus') == 'S' || result.get(1).get('resultCode') == 'DUPLICATE_SFID') {
						mp.RelationStatus__c = '30連携完了';
						mp.MID__c = result.get(2).get('merchantId');
						mp.SID__c = result.get(2).get('storeId');
						refNext = pageStep5(next);
					} else {
						mp.RelationStatus__c = '80連携エラー';
						// 連携失敗は社内再調査の申込完了画面に遷移
						refNext = pageInterruption();
					}
				}
			}
		}
			
		if (index == '2') {
			// QRコード有効化画面からの遷移

			// 必須チェック
			if (String.isBlank(mp.QrCodeUrl__c)) {
				mp.QrCodeUrl__c.addError('PayPayコードから読み取ったURLを入力して下さい。');
				Error = '入力されたデータに不備があります。エラー内容を確認してください。';
			} else if (! Pattern.matches('^https://qr.paypay.ne.jp/.*', mp.QrCodeUrl__c)){
				mp.QrCodeUrl__c.addError('入力された内容がPayPayコードのURLではありません。');
				Error = '入力されたデータに不備があります。エラー内容を確認してください。';
			}
			if (Error != '') return null;
			
			// アクティベートAPIをコールし、QRコードを有効化する
			String stickerId = mp.QrCodeUrl__c.substringAfter('https://qr.paypay.ne.jp/');
			if (stickerId.startsWith('28180105')) {
				stickerId = '05-' + stickerId.substring(8, stickerId.length());
			}
			System.debug(stickerId);
			if (!Pattern.matches('^05-[0-9a-zA-Z]+$', stickerId)) {
				mp.QrCodeUrl__c.addError('入力された内容がPayPayコードのURLではありません。');
				Error = '入力されたデータに不備があります。エラー内容を確認してください。';
				return null;
			}
			
			Map<String, String> result = mpOuterApi.executeActivation(stickerId, originalMp.MID__c, originalMp.SID__c);
			if (result.isEmpty() || result.get('error_code') != null) {
				// ACTIVATE失敗

				// エラー時はQR情報を参照し、該当店舗でACTIVATE成功してたら成功とみなす
				Map<String, String> checkResult = mpOuterApi.checkActivation(stickerId);
				if (checkResult.isEmpty() || checkResult.get('error_code') != null) {
					// 参照もエラーなら、ACTIVATE時のエラーを残す。
					mp.QrCodeActivateResult__c = '{"error_code": "'+result.get('error_code')+'", "error_message": "'+result.get('error_message')+'('+ checkResult.get('error_code') +')"}';
					// 有効化エラー画面に遷移
					mp.QRActivateError__c = true;
					refNext = pageStep5(next);
				} else {
					if (checkResult.get('merchant_id') != originalMp.MID__c
					   || checkResult.get('store_id') != originalMp.SID__c
					   || checkResult.get('sticker_id') != stickerId
					   || checkResult.get('status') != 'ACTIVE'
					) {
						mp.QrCodeUrl__c.addError('すでに利用中のQRコードです。他のQRコードを使用してください。');
						Error = '入力されたデータに不備があります。エラー内容を確認してください。';
						return null;
					}
					// APIレスポンスを連携結果に設定
					mp.QrCodeActivateResult__c = checkResult.get('body');
					// 有効化完了画面へ
					mp.QRActivateError__c = false;
					refNext = pageStep6();
				}
			} else {
				// ACTIVATE成功

				// APIレスポンスを連携結果に設定
				mp.QrCodeActivateResult__c = result.get('body');
				
				if (result.get('status') == 'ACTIVE') {
					// 有効化完了画面へ
					mp.QRActivateError__c = false;
					refNext = pageStep6();
				} else {
					// 有効化エラー画面に遷移
					mp.QRActivateError__c = true;
					refNext = pageStep5(next);
				}
			}
		}

		try {
			save(mp);
		} catch (DmlException e) {
			for (Integer i = 0; i < e.getNumDml(); i++) {
				system.debug(e.getDmlMessage(i));
			}
			// データ保存失敗は社内再調査の申込完了画面に遷移
			return pageInterruption();
		}
		return refNext;
	}

	public Boolean getIsKycCenterOpen() {
		// KYCの審査センターの営業時間内かチェック
		String week = Datetime.now().format('E', 'JST');
		if (week == 'Sun' || week == 'Sat') return false;
		Integer hour = Integer.valueOf(Datetime.now().format('H', 'JST'));
		return 10 <= hour && hour <18; // 10時〜18時まで
	}

	public Boolean getIsReviewCenterOpen() {
		// KYCの審査センターの営業時間内かチェック
		String week = Datetime.now().format('E', 'JST');
		if (week == 'Sun' || week == 'Sat') return false;
		Integer hour = Integer.valueOf(Datetime.now().format('H', 'JST'));
		Integer min = Integer.valueOf(Datetime.now().format('m', 'JST'));
		return (9 <= hour && hour <17) || (hour == 17 && min <= 30); // 9時〜17時30分まで
	}
	/******** ファイルアップロード関連のメソッド ********/
	public PageReference upload1() {
		return upload('corp1');
	}
	public PageReference upload2() {
		return upload('corp2');
	}
	public PageReference upload3() {
		return upload('license1');
	}
	public PageReference upload4() {
		return upload('license2');
	}
	public PageReference upload5() {
		return upload('license3');
	}
	public PageReference upload6() {
		return upload('license4');
	}
	public PageReference upload7() {
		return upload('license5');
	}
	public PageReference uploadAddtional1() {
		return upload('addtional1');
	}
	public PageReference uploadAddtional2() {
		return upload('addtional2');
	}
	public PageReference uploadAddtional3() {
		return upload('addtional3');
	}
	public PageReference uploadAddtional4() {
		return upload('addtional4');
	}

	public String base64String{get;set;}
	public PageReference uploadStoreIn() {
		return uploadStore('storeIn');
	}
	public PageReference uploadStoreOut() {
		return uploadStore('storeOut');
	}
	private PageReference uploadStore(String index) {
		Error = '';
		attachment = new Attachment();
		if (String.isBlank(base64String)) {
			Error = '画像を添付してください。';
			return null;
		}
		try {
			Blob body = EncodingUtil.base64Decode(base64String);
			if (body.size() > 4*1024*1024) {
				Error = '画像サイズは4MB以下にしてください。';
				base64String = '';
				attachment = new Attachment();
				return null;
			}
			attachment.Body = body;
		} catch(Exception ex) {
			Error = '画像を添付してください。';
			base64String = '';
			attachment = new Attachment();
			return null;
		}
		base64String = '';
		attachment.Name = Datetime.now().format('yMMddHHmmss') + '.png';
		return upload(index);
	}

	private PageReference upload(String index) {
		String key = '';
		String prefix = '確認書類_';
		
		system.debug('upload処理開始');
		PageReference check = checkStatus();
		if (check != null) return check;

		try{
			switch on index {
				when 'corp1'{ key = originalMp.CorporateForm__c+'1';}
				when 'corp2' { key = originalMp.CorporateForm__c+'2';}
				when 'license1'{ key = '許認可1';}
				when 'license2'{ key = '許認可2';}
				when 'license3'{ key = '許認可3';}
				when 'license4'{ key = '許認可4';}
				when 'license5'{ key = '許認可5';}
				when 'storeIn'   { prefix='';key = '店舗内観';}
				when 'storeOut'{ prefix='';key = '店舗外観';}
				when 'addtional1'{ prefix='自治体契約協定書_';key = Datetime.now().format('yyyy/MM/dd_HH:mm:ss');}
				when 'addtional2'{ prefix='一括入金業務委託契約_';key = Datetime.now().format('yyyy/MM/dd_HH:mm:ss');}
				when 'addtional3'{ prefix='入金口座誓約書契約_';key = Datetime.now().format('yyyy/MM/dd_HH:mm:ss');}
				when 'addtional4'{ prefix='手数料同意書_';key = Datetime.now().format('yyyy/MM/dd_HH:mm:ss');}
				when else {
					return null;
				}
			}
			attachment.Name =  prefix + key + '_' + attachment.Name;

			attachment.ParentId = PageId;
			attachment.IsPrivate = false;
			insert attachment;
			if(! isUploaded(key)) {
				uploadedFiles.put(key, True);
			}
			additionalUploadFinish = null;
			switch on index {
				when 'addtional1'{ additionalFileCnt1++;}
				when 'addtional2'{ additionalFileCnt2++;}
				when 'addtional3'{ additionalFileCnt3++;}
				when 'addtional4'{ additionalFileCnt4++;}
			}
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
			system.debug('添付ファイルが正常に保存できませんでした。');
		} finally {
			attachment = new Attachment();
		}
		return null;
	}

	public Boolean getIsUploadedCorpAttachment1(){
		return isUploaded(originalMp.CorporateForm__c+'1');
	}
	public Boolean getIsUploadedCorpAttachment2(){
		return isUploaded(originalMp.CorporateForm__c+'2');
	}
	public Boolean getIsUploadedLicense1(){
		return isUploaded('許認可1');
	}
	public Boolean getIsUploadedLicense2(){
		return isUploaded('許認可2');
	}
	public Boolean getIsUploadedLicense3(){
		return isUploaded('許認可3');
	}
	public Boolean getIsUploadedLicense4(){
		return isUploaded('許認可4');
	}
	public Boolean getIsUploadedLicense5(){
		return isUploaded('許認可5');
	}
	public Boolean getIsUploadedStoreIn(){
		return isUploaded('店舗内観');
	}
	public Boolean getIsUploadedStoreOut(){
		return isUploaded('店舗外観');
	}
	public Boolean getIsUploadedStoreInCheck(){
		return isUploadedCheck('店舗内観写真');
	}
	public Boolean getIsUploadedStoreOutCheck(){
		return isUploadedCheck('店舗外観写真');
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
	public Boolean additionalUploadFinish {
		get{
			if (additionalUploadFinish == null) {
				additionalUploadFinish = (
						(originalMp.AgreementType__c != '自治体契約' || additionalFileCnt1 > 0)
						&& (originalMp.DepositAccountType__c != '一括入金業務委託契約' || additionalFileCnt2 > 0)
						&& (originalMp.DepositAccountType__c != '誓約書契約' || additionalFileCnt3 > 0)
						//&& (!originalMp.CommissionTargetFlag__c || additionalFileCnt4 > 0)
					);
			}
			return additionalUploadFinish;
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
	/*
	public PageReference uploadStore() {
		Error = '';
		attachmentOut = new Attachment();
		attachmentIn = new Attachment();
		
		try {
			
			if(!isUploadedCheck('店舗外観写真')){
				if (String.isBlank(base64StringOut)) {
					Error = '画像を添付してください。';
					return null;
				}
			}
			
			if(!isUploadedCheck('店舗内観写真')){
				if (String.isBlank(base64StringIn)) {
					Error = '画像を添付してください。';
					return null;
				}
			}
			
			Blob bodyOut = EncodingUtil.base64Decode(base64StringOut);
			Blob bodyIn = EncodingUtil.base64Decode(base64StringIn);
			if (bodyOut.size() > 4*1024*1024) {
				Error = '画像サイズは4MB以下にしてください。';
				base64StringOut = '';
				attachmentOut = new Attachment();
				return null;
			}
			
			if (bodyIn.size() > 4*1024*1024) {
				Error = '画像サイズは4MB以下にしてください。';
				base64StringIn = '';
				attachmentIn = new Attachment();
				return null;
			}
			if(!String.isBlank(base64StringOut)){
				attachmentOut.Body = bodyOut;
			}
			if(!String.isBlank(base64StringIn)){
				attachmentIn.Body = bodyIn;
			}
		} catch(Exception ex) {
			Error = '画像を添付してください。';
			base64StringOut = '';
			base64StringIn = '';
			attachmentOut = new Attachment();
			attachmentIn = new Attachment();
			return null;
		}
		base64StringOut = '';
		base64StringIn = '';
		attachmentOut.Name = base64StringOutFileName;
		attachmentIn.Name = base64StringInFileName;
		return upload();
	}
	*/
	private void upload() {
		try{
			if(attachmentOut.Body!=null){
				attachmentOut.Name =  '店舗外観写真' +  attachmentOut.Name;
				attachmentOut.ParentId = PageId;
				attachmentOut.IsPrivate = false;
				insert attachmentOut;
			}
			if(attachmentIn.Body!=null){
				attachmentIn.Name =  '店舗内観写真' +  attachmentIn.Name;
				attachmentIn.ParentId = PageId;
				attachmentIn.IsPrivate = false;
				insert attachmentIn;
			}
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'添付ファイルが正常に保存できませんでした。'));
			system.debug('添付ファイルが正常に保存できませんでした。');
		} finally {
			attachmentOut = new Attachment();
			attachmentIn = new Attachment();
		}
	}
	
	private Boolean isUploadedCheck(String target) {

			uploadedFiles = new Map<String, Boolean>();
			List<Attachment> files = [select Id, Name from Attachment where parentId =:PageId
							and (Name Like :('確認書類_%') or Name Like :('店舗%')) order By LastModifiedDate Desc Limit 100];
			if (! files.isempty()) {
				for (Attachment file : files) {
					String prefix = file.Name.replace('確認書類_', '').replaceAll('_.*$', '');
					system.debug('prefix'+prefix);
					if (prefix.contains(target)) {
						uploadedFiles.put(target, True);
					}
				}
			}
		system.debug('uploadedFiles.containsKey(target)'+uploadedFiles.containsKey(target));
		return uploadedFiles.containsKey(target);
	}

	/**
	 *　審査対象日時登録/更新 処理
	 * 
	 **/
	private void upsertExaminationDateTime(Id mpOpportunityId){
		Id RecordTypeOpportunityReview = mpHistory__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('mpOpportunityReview').getRecordTypeId();
		List<mpHistory__c> targetHistoryList  = new List<mpHistory__c>();
		targetHistoryList = [SELECT Id, examinationDateTime__c 
										FROM mpHistory__c 
										WHERE RecordTypeId = :RecordTypeOpportunityReview AND 
											  mpRelation__c = :mpOpportunityId Limit 1];
		//審査履歴（レコードタイプ：アタックリスト審査）レコードが登録されていない場合insert
		//登録されている場合はupdate
		if (targetHistoryList.size() == 0) {
			try {
				mpHistory__c history = new mpHistory__c(
				mpRelation__c  = mpOpportunityId,
				RecordTypeId = RecordTypeOpportunityReview,
				examinationDateTime__c =  Datetime.now()   //審査対象日時
			);
			insert history;
			//paypayアタックリストと審査履歴(レコードタイプ:アタックリスト審査)関連付け
			//仮/本審査 mpOpportunityReview__c
			mp.mpOpportunityReview__c = history.Id;
			update mp;

			} catch(Exception ex) {
				System.debug(ex.getMessage());
			}
		} else {
			if (targetHistoryList.get(0).examinationDateTime__c == NULL) {
				//審査対象日時（初期値固定）
				targetHistoryList.get(0).examinationDateTime__c = Datetime.now();

				try {
					update targetHistoryList;
				} catch(Exception ex) {
					System.debug(ex.getMessage());
				}
			}
		}
	}

	/**
	 *　一次審査可決日 登録/更新処理
	 * 
	 **/
	private void upsertFirstReviewPassedDate(Id mpOpportunityId){
		Id RecordTypeOpportunityReview = mpHistory__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('mpOpportunityReview').getRecordTypeId();
		List<mpHistory__c> targetHistoryList  = new List<mpHistory__c>();
		targetHistoryList = [SELECT Id, ReviewPersonFirstDate__c, FirstReviewPassedDate__c 
										FROM mpHistory__c 
										WHERE RecordTypeId = :RecordTypeOpportunityReview AND 
											  mpRelation__c = :mpOpportunityId Limit 1];
		//審査履歴（レコードタイプ：アタックリスト審査）レコードが登録されていない場合insert
		//登録されている場合はupdate
		if (targetHistoryList.size() == 0) {
			try {
				mpHistory__c history = new mpHistory__c(
				mpRelation__c  = mpOpportunityId,
				RecordTypeId = RecordTypeOpportunityReview,
				ReviewPersonFirstDate__c =  Datetime.now().format(),  //一次審査可決日
				FirstReviewPassedDate__c =  Datetime.now().format()   //審査担当者初回着手日
			);
			insert history;
			//paypayアタックリストと審査履歴(レコードタイプ:アタックリスト審査)関連付け
			//仮/本審査 mpOpportunityReview__c
			mp.mpOpportunityReview__c = history.Id;
			update mp;

			} catch(Exception ex) {
				System.debug(ex.getMessage());
			}
		} else {
			//一次審査可決日（可変値）
			targetHistoryList.get(0).FirstReviewPassedDate__c = Datetime.now().format();
			if (targetHistoryList.get(0).ReviewPersonFirstDate__c == NULL) {
				//審査担当者初回着手日（初期値固定）
				targetHistoryList.get(0).ReviewPersonFirstDate__c = Datetime.now().format();
			}
			try {
				update targetHistoryList;
			} catch(Exception ex) {
				System.debug(ex.getMessage());
			}
		}
	}

	/**
	 * スマスタフォームの時
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
		}catch (DmlException ex) {
			return 'error';
		}
	}

	/**
	 * スマスタフォームの時PayPay商品券同意を設定
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
	
	/**
	 * スマスタフォームの時
	 * 特定の[お取り扱い商品2]（ProductName__c）を選択した場合はAlipay同意パネル非表示
	 */
	public List<String> getAlipayProductName() {
		List<String> result = new List<String>();
		for (ProductNameNotCoveredbyAlipay__mdt nameList :[
				SELECT DeveloperName, MasterLabel
				FROM ProductNameNotCoveredbyAlipay__mdt
				ORDER BY MasterLabel
			]) {
			result.add(nameList.MasterLabel);
		}
		return result;
	}

	/**
	 * スマスタフォームの時
	 * 特定の[お取り扱い商品2]（ProductName__c）を選択した場合はライトプラン同時申し込み用パネル非表示
	 */
	public List<String> getPageSkipProductName() {
		List<String> result = new List<String>();
		for (PageSkipList__mdt nameList :[
				SELECT DeveloperName, MasterLabel
				FROM PageSkipList__mdt
				ORDER BY MasterLabel
			]) {
			result.add(nameList.MasterLabel);
		}
		return result;
	}

}