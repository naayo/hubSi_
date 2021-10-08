public class TestFactory {
    
    // Create a new account
    public static Account createDistributeur(){
        
        Account a = new Account();
        a.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Distributeur');
        a.Name = 'Test Account';
        a.ShippingCity = 'Lyon';
        a.ShippingStreet = '123 place de la Belote';
        a.Type_caution__c = 'Magasin';
        return a;
    }
    
    // Create a new client
    public static Account createClient(){
        
        Account a = new Account();
        a.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Client_location');
        a.FirstName = 'externaluser' + Datetime.now().getTime(); 
        a.LastName = 'Test';
        a.PersonEmail = 'externaluser' + Datetime.now().getTime() + '@company.com';
        a.ShippingCity = 'Lyon';
        a.ShippingStreet = '123 place de la Belote';
        return a;
    }
    
    // Create a new Gamme produit
    public static Gamme__c createGammeProduit(){
        
        // Create a new Gamme
        Gamme__c g = new Gamme__c();
        g.Name = 'Agile';
        g.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Gamme_produit');
        g.Valeur_Maximale_Produit__c = 1000;
        g.Valeur_Minimale_Produit__c = 10;
        return g;
    }
    
    // Create a new Gamme Formule
    public static Gamme__c createGammeFormule(){
        
        // Create a new Gamme
        Gamme__c g = new Gamme__c();
        g.Name = 'Aventure';
        g.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Gamme_formule');
        return g;
    }
    
    // Create a Table de Decompte
    public static Table_decompte__c createTableDecompte(){
        
        Gamme__c go = createGammeFormule();
        insert go;
        Gamme__c gp = createGammeProduit();
        insert gp;        
        
        // Create a Table de Decompte
        Table_decompte__c t = new Table_decompte__c();
        t.Gamme_formule__c = go.id;
        t.Gamme_produit__c = gp.id;
        t.Coefficient_decompte__c = 1;
        return t;
    }
    
    // Create a new Formule
    public static Product2 createFormule(){
        
        // Create the related Gamme
        Gamme__c g = createGammeFormule();
        insert g;
        
        // Create a new Formule
        Product2 o = createFormule(g.id);
        o.Name = g.Name + ' ' + o.Nombre_jours_inclus__c + ' JOURS / MOIS';
        return o;
    }
    
    // Create a new Formule
    public static Product2 createFormule(Id gammeId){
        
        // Create a new Formule
        Product2 o = new Product2();
        o.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Formule_location');
        o.Gamme_formule__c = gammeId;
        o.Nombre_jours_inclus__c = 4;
        o.Prix_mensuel__c = 19.9;
        o.Tarif_depassement__c = 10;
        o.Duree_formule_mois__c = 12;
        o.Nombre_jours_carence__c = 0;
        o.Name = 'Gamme' + ' ' + o.Nombre_jours_inclus__c + ' JOURS / MOIS';
        return o;
    }
    
    // Create a new Contract
    public static Asset createContract(){
        
        // Create a Table de decompte
        Table_decompte__c t = TestFactory.createTableDecompte();
        insert t;
        
        // Create the related account and formule
        Account a = createClient();
        insert a;
        
        Product2 o = createFormule(t.Gamme_formule__c);
        insert o;
        
        // Create a new contract
        Asset c = new Asset();
        c.Name = '123548s';
        c.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Contrat_location');
        c.AccountId = a.id;
        c.Date_debut_contrat__c = System.today();
        c.Code_formule__c = o.id;
        return c;
    }
    
    // Create a new Contract
    public static Asset createContract(id accountId){
        
        // Create a Table de decompte
        Table_decompte__c t = TestFactory.createTableDecompte();
        insert t;
        
        Product2 o = createFormule(t.Gamme_formule__c);
        insert o;
        
        // Create a new contract
        Asset c = new Asset();
        c.Name = '123548s';
        c.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Contrat_location');
        c.AccountId = accountId;
        c.Date_debut_contrat__c = System.today();
        c.Code_formule__c = o.id;
        return c;
    }
    
    // Create a new formule
    public static vlocity_ins__AssetCoverage__c createFormuleOption(){
        
        // Create another formule
        Product2 o = createFormule();
        insert o;
        
        vlocity_ins__AssetCoverage__c f = new vlocity_ins__AssetCoverage__c();
        f.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Formule_option_location');
        f.Formule_options__c = o.id;
        return f;
    }
    
    // Create a new Emprunt
    public static Emprunt__c createEmprunt(Asset contract){
        
        // Create a new Stock
        Stock_Produit__c s = createStock();
        insert s;
        
        // Create a new emprunt
        Emprunt__c e = new Emprunt__c();
        e.Caution_recue__c = FALSE;
        e.Contrat__c = contract.Id;
        e.Client__c = contract.AccountId;
        e.Produit_emprunte__c = s.id;
        e.Point_de_vente_sortie__c = [SELECT Distributeur_de_reference__c 
                                      FROM User 
                                      WHERE id =: UserInfo.getUserId()][0].Distributeur_de_reference__c;
        return e;
    }
    
    // Create a new Emprunt
    public static Emprunt__c createEmprunt(Asset contract, Stock_Produit__c s){
        
        // Create a new emprunt
        Emprunt__c e = new Emprunt__c();
        e.Caution_recue__c = FALSE;
        e.Contrat__c = contract.Id;
        e.Client__c = contract.AccountId;
        e.Produit_emprunte__c = s.id;
        e.Point_de_vente_sortie__c = [SELECT Distributeur_de_reference__c 
                                      FROM User 
                                      WHERE id =: UserInfo.getUserId()][0].Distributeur_de_reference__c;
        return e;
    }
    
    // Create a new Product
    public static Product2 createProduct(){
        
        Product2 p = new Product2();
        p.recordTypeId = UtilityClassHelper.getCreatedRecordType('Produit_location');
        p.Name = 'Super test product';
        p.Produit_avec_numero_de_serie__c = FALSE;
        p.Prix_indicatif__c = 199;
        return p;        
    }
    
    // Create a new stock
    public static Stock_Produit__c createStock(id pId){
        
        Stock_Produit__c s = new Stock_Produit__c();
        s.Produit__c = pId;
        s.Date_entree__c = system.today();
        s.Code_distributeur_stock__c = [SELECT Distributeur_de_reference__c 
                                        FROM User 
                                        WHERE id =: UserInfo.getUserId()][0].Distributeur_de_reference__c;
        s.Statut__c = 'En stock';
        s.Etat__c = 'Neuf';
        return s;
    }
    
    // Create a new stock
    public static Stock_Produit__c createStock(){
        
        // Create a new product
        Product2 p = createProduct();
        insert p;
        
        Stock_Produit__c s = new Stock_Produit__c();
        s.Produit__c = p.id;
        s.Date_entree__c = system.today();
        s.Code_distributeur_stock__c = [SELECT Distributeur_de_reference__c 
                                        FROM User 
                                        WHERE id =: UserInfo.getUserId()][0].Distributeur_de_reference__c;
        s.Statut__c = 'En stock';
        s.Etat__c = 'Neuf';
        return s;
    }
    
    // Create a reservation
    public static Reservation__c createReservation(){
        
        // Create a client
        Account c = createClient();
        insert c;
        
        // Create a stock
        Stock_Produit__c s = createStock();
        insert s;
        
        Reservation__c r = new Reservation__c();
        r.Client__c = c.id;
        r.produit_reserve__c = s.id;
        r.Date_retrait__c = system.today();
        r.Duree_emprunt__c = 1;
        return r;
    }
    
    // Create a reservation
    public static Reservation__c createReservation(id accountId){
        
        // Create a stock
        Stock_Produit__c s = createStock();
        insert s;
        
        Reservation__c r = new Reservation__c();
        r.Client__c = accountId;
        r.produit_reserve__c = s.id;
        r.Date_retrait__c = system.today();
        r.Duree_emprunt__c = 1;
        return r;
    }
    
    // Create a reservation
    public static Reservation__c createReservation(Stock_Produit__c s){
        
        // Create a client
        Account c = createClient();
        insert c;
        
        Reservation__c r = new Reservation__c();
        r.Client__c = c.id;
        r.produit_reserve__c = s.id;
        r.Date_retrait__c = system.today();
        r.Duree_emprunt__c = 1;
        return r;
    }
    
    // Create a reservation
    public static Reservation__c createReservation(id accountId, id stockId){
        
        Reservation__c r = new Reservation__c();
        r.Client__c = accountId;
        r.produit_reserve__c = stockId;
        r.Date_retrait__c = system.today();
        r.Duree_emprunt__c = 1;
        return r;
    }
    
    // Create a user
    public static User createUser(){
        
        User u = new User();
        u.FirstName = 'Michael';
        u.LastName = 'Jockson';
        u.email = 'michael.jockson@123.com';
        u.username = 'michael.jockson@123.com';
        u.Alias = 'mjo';
        u.TimeZoneSidKey = 'GMT';
        u.LocaleSidKey = 'fr_FR_EURO';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.LanguageLocaleKey = 'fr';        
        return u;
    }
    
    // Create a alert
    public static Alert__c createAlert(id sinistre){
        
        Alert__c al = new Alert__c();
        al.Case__c = sinistre;
        al.Description__c = 'Error';
        al.Status__c = 'Waiting';
        al.RuleCode__c = 'RGSINXX';
        return al;
    }
    
    // Create a CalculIndem
    public static Mouvements_financiers__c createMouvementFinancier(id sinistre){
        
        Mouvements_financiers__c mf = new Mouvements_financiers__c();
        mf.Case__c = sinistre;
        mf.Cout_choisi__c = 'Primes';
        mf.Date_mouvement__c = System.today();
        mf.Libelle__c = 'test';
        mf.Montant__c = 1000;
        mf.Name = 'Prime pour reparation par le client';
        mf.Sens_mouvement__c = 'Interne reparation';
        mf.Statut__c = 'Crée';
        mf.Type_mouvement__c = 'Prime pour reparation par le client';
        return mf;
    }
    
    // Create a Type de piece justificative
    public static Types_piece_justificative__c createTypePJ(String typePJName){
        
        Types_piece_justificative__c t = new Types_piece_justificative__c();
        t.Perte__c = TRUE;
        t.Name = typePJName;
        t.LongTitle__c = 'Intitulé de ' + typePJName;
        t.NoTradable__c = true;
        return t;
    }
    
    // Create a piece justificative
    public static Piece_justificative_Sinistre__c createPJ(Types_piece_justificative__c t){
        
        Piece_justificative_Sinistre__c pj = new Piece_justificative_Sinistre__c();
        pj.Validite_document__c = 'expected';
        pj.Name = t.Name;
        return pj;
    }
    
    // Create a new Contract assurance
    public static Asset createAssuranceAsset(){
        
        // Create the related account and formule
        Account a = createClient();
        insert a;
        
        // Create a new contract
        Asset c = new Asset();
        c.Name = '123548s';
        c.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Contrat_assurance');
        c.AccountId = a.id;
        c.Date_debut_contrat__c = System.today();
        return c;
    }
    
    // Create a new Contract assurance
    public static List<Asset> createAssuranceAssetList(integer assetCount){
        
        id InsuranceRT = UtilityClassHelper.getCreatedRecordType('Contrat_assurance');
        
        // Create the related account
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i<assetCount; i++){
            Account a = createClient();
            accList.add(a);
        }
        insert accList;
            
        // Create a new contract
        List<Asset> assetList = new List<Asset>();
        for(Integer i = 0; i<assetCount; i++){
            Asset c = new Asset();
            c.Name = '123548s';
            c.RecordTypeId = InsuranceRT;
            c.AccountId = accList[i].id;
            c.Date_debut_contrat__c = System.today();
            assetList.add(c);
        }
        return assetList;
    }
    
    // Create a new Contract assurance
    public static Asset createAssuranceAsset(id accountId){
        
        // Create a new contract
        Asset c = new Asset();
        c.Name = '123548s';
        c.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Contrat_assurance');
        c.AccountId = accountId;
        c.Date_debut_contrat__c = System.today();
        return c;
    }
    
    // Create a sinistre
    public static Case createSinistre(){
        
        // Create an account
        Account a = TestFactory.createClient();
        insert a;
        
        // Create a case
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = a.id;
        c.RecordTypeId = caseSinistreId;
        c.Typologie_Sinistre__c = 'Lost';        
        return c;
    }
    
    // Create a sinistre
    public static Case createSinistre(id accountId){
        
        // Create a case
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = accountId;
        c.RecordTypeId = caseSinistreId;
        c.Typologie_Sinistre__c = 'Lost';        
        return c;
    }
    
    // Create a sinistre
    public static Case createSinistre(id accountId, id assetId){
        
        // Create a case
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = accountId;
        c.AssetId = assetId;
        c.RecordTypeId = caseSinistreId;
        c.Typologie_Sinistre__c = 'Lost';        
        return c;
    }
    
    // Create a sinistre
    public static List<Case> createSinistreList(List<Account> accList, List<Asset> assetList, Integer sinistreCount){
        
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        
        // Create n cases
        List<Case> caseList = new List<Case>();
        for(Integer i = 0; i<sinistreCount; i++){
            Case c = new Case();
            c.AccountId = accList[0].id;
            c.AssetId = assetList[0].id;
            c.RecordTypeId = caseSinistreId;
            c.Typologie_Sinistre__c = 'Lost';
            caseList.add(c);
        }   
        return caseList;
    }
    
    // Create a new Contract assurance with formule soucrite and formule
    public static Asset createAssuranceAssetWithFormula(){
        
        // Create the related account and formule
        Account a = createClient();
        insert a;
        
        // Create a new contract
        Asset c = new Asset();
        c.Name = '0220010102';
        c.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Contrat_assurance');
        c.AccountId = a.id;
        c.Date_debut_contrat__c = System.today();
        c.Id_externe__c = 'INS0220010102';
        c.Id_contrat_B_appli__c = '5343473';
        c.TECH_CalculatorIndicLastChange__c = System.today().addMonths(12);
        c.TECH_LastBirthDayContract__c = System.today().addMonths(-12);
        insert c;
        
        vlocity_ins__AssetCoverage__c asetCo = createFormuleOptionInsurer();
        asetCo.vlocity_ins__PolicyAssetId__c = c.Id;
        insert asetCo;
        
        c.Formule__c = asetCo.id;
        update c;
        
        return c;
    }
    
    // Create a new Formule insurer
    public static Product2 createFormuleInsurer(){
        
        // Create a new Formule
        Product2 o = new Product2();
        o.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Assurance','Product2');
        o.vlocity_ins__Type__c = 'Formula';
        o.Canal_distributeur__c = 'DARTY';
        o.Pertes_valeur_achat__c = 300;
        o.Nombre_echanges__c = 3;
        o.Nombre_mobiles_couverts__c = 1;
        o.Nombre_produits_multimedia_couverts__c = 0;
        o.Nombre_produits_assures__c = '1';
        o.Plafond__c = 2500;
        o.FranchiseLevel1__c = 29;
        o.FranchiseLevel2__c = 79;
        o.FranchiseLevel3__c = 100;
        o.FranchiseAmount1__c = 350;
        o.FranchiseAmount2__c = 500;
        o.FranchiseAmount3__c = 2500;
        o.Casse__c = true;
        o.Reparation__c = true;
        o.Vol_Caracterise__c = true;
        o.Vol_toute_cause__c = true;
        o.Communication_frauduleuse__c = true;
        o.Oxydation__c = false;
        o.Tout_risques__c = true;
        o.NbMounthKPIContract__c = 12;
        o.Name = 'ABSOLUE';
        return o;
    }
    
    // Create a new formule
    public static vlocity_ins__AssetCoverage__c createFormuleOptionInsurer(){
        
        // Create another formule
        Product2 o = createFormuleInsurer();
        insert o;
        
        vlocity_ins__AssetCoverage__c f = new vlocity_ins__AssetCoverage__c();
        f.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Assurance','vlocity_ins__AssetCoverage__c');
        f.Formule_options__c = o.id;
        return f;
    }
    
    // Create a new formule
    public static vlocity_ins__AssetCoverage__c createFormuleOptionInsurer(id productId){
        
        vlocity_ins__AssetCoverage__c f = new vlocity_ins__AssetCoverage__c();
        f.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Assurance','vlocity_ins__AssetCoverage__c');
        f.Formule_options__c = productId;
        return f;
    }
    
    // Create a reclamation
    public static Case createReclamation(id accountId, id assetId){
        
        // Create a case
        id caseReclamationId = UtilityClassHelper.getCreatedRecordType('Reclamation');
        Case c = new Case();
        c.AccountId = accountId;
        c.AssetId = assetId;
        c.RecordTypeId = caseReclamationId;
        c.Origin = 'Forum';
        c.Applicant__c = 'Client';
        c.Transmitter__c = 'Client';
        c.CanalChannel__c = 'Email';
        c.Email_Contact__c  = 'test@yopmail.com';
        return c;
    }
    
    // Create a matrice
    public static Matrice_cout_equipement__c createMatrice(id idTerminal, Boolean isExchanged){
        Matrice_cout_equipement__c mce = new Matrice_cout_equipement__c();
        mce.Product2Id__c = idTerminal;
        mce.Disponible_Echange__c = isExchanged;
        mce.GradeCost_1__c = 150;
        mce.GradeCost_2__c = 200;
        mce.GradeCost_3__c = 350;
        mce.PlanCost_1__c = 200;
        mce.Valeur_equipement__c = 400;
        mce.Date_valeur__c = System.Date.today();
        return mce;
    }
    
    // Create n colis
    public static List<Colis__c> createColis(Integer n){
        
        List<Colis__c> colisList = new List<Colis__c>();
        
        for(Integer i = 0; i<n; i++){
            Colis__c c = new Colis__c();
            c.Name = system.today() + 'LaPosteSav' + i;
            c.Date_reception__c = system.today();
            c.Nom_transporteur__c = 'LaPosteSav';
            colisList.add(c);
        }
        
        return colisList;
    }
}