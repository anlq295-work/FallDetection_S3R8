import '../core/models.dart';

/// Complete tri-lingual dictionary: Vietnamese (default), English, French.
/// Zero hardcoded generic person names or fake phone numbers!
class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  String _t(String vi, String en, String fr) {
    switch (lang) {
      case AppLanguage.vi:
        return vi;
      case AppLanguage.en:
        return en;
      case AppLanguage.fr:
        return fr;
    }
  }

  // Brand & common
  String get appName => 'Hearth';
  String get back => _t('Quay lại', 'Back', 'Retour');
  String get cancel => _t('Hủy', 'Cancel', 'Annuler');
  String get continueBtn => _t('Tiếp tục', 'Continue', 'Continuer');
  String get done => _t('Xong', 'Done', 'Terminé');
  String get save => _t('Lưu', 'Save', 'Enregistrer');
  String get retry => _t('Thử lại', 'Try again', 'Réessayer');
  String get close => _t('Đóng', 'Close', 'Fermer');
  String get openSettings => _t('Mở cài đặt', 'Open settings', 'Ouvrir les réglages');
  String get language => _t('Ngôn ngữ', 'Language', 'Langue');
  String get appearance => _t('Giao diện', 'Appearance', 'Apparence');
  String get themeSystem => _t('Theo máy', 'System', 'Système');
  String get themeLight => _t('Sáng', 'Light', 'Clair');
  String get themeDark => _t('Tối', 'Dark', 'Sombre');
  String get requiredFieldError => _t(
        'Vui lòng điền thông tin bắt buộc này.',
        'Please complete this required field.',
        'Veuillez remplir ce champ obligatoire.',
      );
  String stepOf(int step, int total) => _t(
        'Bước $step / $total',
        'Step $step of $total',
        'Étape $step sur $total',
      );

  // Neutral fallback when personName is not configured yet
  String personOrGeneric(String personName) =>
      personName.trim().isNotEmpty ? personName.trim() : _t('người thân', 'your loved one', 'votre proche');

  // Tabs
  String get tabHome => _t('Trang chủ', 'Home', 'Accueil');
  String get tabActivity => _t('Hoạt động', 'Activity', 'Activité');
  String get tabSettings => _t('Cài đặt', 'Settings', 'Réglages');

  // Room types
  String roomTypeName(RoomType type) {
    switch (type) {
      case RoomType.livingRoom:
        return _t('Phòng khách', 'Living room', 'Salon');
      case RoomType.bedroom:
        return _t('Phòng ngủ', 'Bedroom', 'Chambre');
      case RoomType.bathroom:
        return _t('Phòng tắm', 'Bathroom', 'Salle de bain');
      case RoomType.kitchen:
        return _t('Nhà bếp', 'Kitchen', 'Cuisine');
      case RoomType.hallway:
        return _t('Hành lang', 'Hallway', 'Couloir');
      case RoomType.other:
        return _t('Phòng khác', 'Other', 'Autre');
    }
  }

  // S1 Welcome & Sign In (with mandatory Caregiver & Monitored Person fields!)
  String get s1Headline => _t(
        'An tâm biết người thân an toàn ở nhà, ngay cả khi bạn đi xa.',
        "Know they're safe at home, even when you're away.",
        'Sachez vos proches en sécurité à la maison, même à distance.',
      );
  String get s1Fact1 => _t(
        'Phát hiện té ngã không cần camera, bảo vệ riêng tư',
        'Detects falls without cameras, preserving privacy',
        'Détecte les chutes sans caméra, vie privée préservée',
      );
  String get s1Fact2 => _t(
        'Báo động đồng thời qua App, SMS, Telegram & cuộc gọi cho cả gia đình',
        'Alerts all carers simultaneously via App, SMS, Telegram & calls',
        'Alerte tous les proches simultanément (App, SMS, Telegram, appels)',
      );
  String get s1Fact3 => _t(
        'Hoạt động độc lập qua Wi-Fi 2.4 GHz & phát còi/đèn tại chỗ',
        'Works over 2.4 GHz home Wi-Fi with local room siren & light',
        'Fonctionne en Wi-Fi 2,4 GHz avec alarme et lumière locales',
      );
  String get s1EmailLabel => _t('Địa chỉ email của bạn *', 'Your email address *', 'Votre adresse e-mail *');
  String get s1EmailPlaceholder => 'ten.cua.ban@email.com';
  String get s1EmailHelper => _t(
        'Chúng tôi sẽ gửi mã 6 chữ số. Không cần nhớ mật khẩu.',
        "We'll send you a 6-digit code. No password needed.",
        'Nous vous enverrons un code à 6 chiffres. Aucun mot de passe requis.',
      );
  String get s1CarerNameLabel => _t('Tên của bạn (người chăm sóc) *', 'Your name (carer) *', 'Votre prénom (aidant) *');
  String get s1CarerNameHint => _t('Ví dụ: Nguyễn An', 'Example: Alex', 'Exemple : Camille');
  String get s1PersonNameLabel => _t('Tên người thân được theo dõi *', 'Person being monitored *', 'Personne suivie *');
  String get s1PersonNameHint => _t('Nhập tên người thân của bạn', 'Enter your relative’s name', 'Saisissez le prénom');
  String get s1PersonPhoneLabel => _t('Số điện thoại người thân (để gọi nhanh khi có sự cố)', 'Monitored person’s phone (for quick call)', 'Téléphone du proche (appel rapide)');
  String get s1SendCode => _t('Gửi mã đăng nhập cho tôi', 'Send me a sign-in code', 'M’envoyer un code de connexion');
  String get s1SendingCode => _t('Đang gửi mã…', 'Sending code…', 'Envoi du code…');
  String get s1AlreadyHaveCode => _t('Tôi đã có mã đăng nhập', 'I already have a code', 'J’ai déjà un code');
  String get s1Legal => _t(
        'Khi tiếp tục, bạn đồng ý với Điều khoản sử dụng và Chính sách bảo mật.',
        'By continuing you agree to the Terms and Privacy notice.',
        'En continuant, vous acceptez les Conditions et la Politique de confidentialité.',
      );
  String get s1CodeLabel => _t('Mã xác nhận 6 chữ số *', '6-digit sign-in code *', 'Code à 6 chiffres *');
  String s1CodeSentTo(String email) => _t(
        'Đã gửi mã tới $email (Mã thử nghiệm: 123456)',
        'Code sent to $email (Test code: 123456)',
        'Code envoyé à $email (Code test : 123456)',
      );
  String get s1SignIn => _t('Xác nhận & Bắt đầu thiết lập', 'Sign in & Start setup', 'Se connecter & Configurer');
  String get s1SigningIn => _t('Đang xác thực…', 'Signing in…', 'Connexion…');
  String s1ResendCountdown(int sec) => _t(
        'Gửi lại mã mới (sau 0:${sec.toString().padLeft(2, '0')})',
        'Send a new code (available in 0:${sec.toString().padLeft(2, '0')})',
        'Renvoyer un code (dans 0:${sec.toString().padLeft(2, '0')})',
      );
  String get s1ResendNow => _t('Gửi mã mới', 'Send a new code', 'Envoyer un nouveau code');
  String get s1EmailError => _t(
        'Email chưa hợp lệ. Hãy kiểm tra ký tự @ và tên miền (ví dụ ten@email.com).',
        'That email looks incomplete. Check it has an @ and a domain.',
        'Cet e-mail semble incomplet. Vérifiez la présence de @ et du domaine.',
      );
  String get s1CodeError => _t(
        'Mã không khớp hoặc đã hết hạn. Kiểm tra email mới nhất hoặc gửi lại mã mới.',
        "That code didn't match or has expired. Check the latest email or send a new code.",
        'Ce code est incorrect ou expiré. Vérifiez votre e-mail ou demandez un nouveau code.',
      );
  String get s1NetworkError => _t(
        'Không có kết nối mạng. Hãy bật Wi-Fi hoặc dữ liệu di động rồi thử lại.',
        'No internet connection. Connect to Wi-Fi or mobile data and try again.',
        'Aucune connexion Internet. Activez le Wi-Fi ou les données mobiles puis réessayez.',
      );
  String get s1SetupIntro => _t(
        'Hãy cài đặt cảm biến đầu tiên (khoảng 5–10 phút). Cắm nguồn cảm biến và chuẩn bị sẵn mật khẩu Wi-Fi 2.4 GHz.',
        "Let's set up your first sensor (5–10 min). Have the sensor plugged in and your 2.4 GHz Wi-Fi password ready.",
        'Configurons votre premier capteur (5–10 min). Branchez-le et préparez le mot de passe Wi-Fi 2,4 GHz.',
      );
  String get s1DesktopHint => _t(
        'Cài đặt lần đầu cần Bluetooth trên điện thoại. Sau khi hoàn tất, bạn có thể theo dõi từ mọi thiết bị.',
        'Setup needs your phone (Bluetooth). You can watch from here afterwards.',
        'La configuration nécessite le Bluetooth du téléphone. Vous pourrez ensuite suivre depuis cet écran.',
      );
  String get s1SkipToHome => _t('Vào Trang chủ để xem trước (thêm cảm biến sau)', 'Enter Home first (add sensors later)', 'Accéder à l’accueil (ajouter un capteur plus tard)');

  // S2 Find Sensor
  String get s2Title => _t('Tìm cảm biến của bạn', 'Find your sensor', 'Trouver votre capteur');
  String get s2Step1 => _t(
        'Cắm nguồn 5V (2A–3A) cho hộp cảm biến trong phòng cần theo dõi.',
        'Plug the sensor into a 5V socket in the room you want to watch.',
        'Branchez le capteur sur une prise 5V dans la pièce à surveiller.',
      );
  String get s2Step2 => _t(
        'Đợi đèn trên cảm biến sẵn sàng (khoảng 10 giây).',
        'Wait until the light on the sensor is ready (about 10 seconds).',
        'Attendez que le voyant du capteur soit prêt (environ 10 secondes).',
      );
  String get s2Step3 => _t(
        'Giữ điện thoại trong phạm vi 2 mét gần cảm biến.',
        'Keep your phone within 2 metres.',
        'Gardez votre téléphone à moins de 2 mètres.',
      );
  String get s2PermissionTitle => _t(
        'Hearth chỉ dùng Bluetooth để kết nối và cấu hình cảm biến ESP32-S3 lần đầu.',
        'Hearth uses Bluetooth only to pair and configure the ESP32-S3 sensor the first time.',
        'Hearth utilise le Bluetooth uniquement pour appairer le capteur ESP32-S3 la première fois.',
      );
  String get s2AllowBluetooth => _t('Cho phép Bluetooth & Quét', 'Allow Bluetooth & Scan', 'Autoriser le Bluetooth');
  String get s2SensorsNearby => _t('Cảm biến ở gần', 'Sensors nearby', 'Capteurs à proximité');
  String get s2Searching => _t('Đang tìm cảm biến ở gần…', 'Searching for sensors nearby…', 'Recherche de capteurs à proximité…');
  String s2SensorRowTitle(String code) => _t(
        'Cảm biến Hearth · Mã cuối $code',
        'Hearth sensor · ID ends in $code',
        'Capteur Hearth · ID finissant par $code',
      );
  String get s2SignalStrong => _t('Tín hiệu mạnh', 'Strong', 'Signal fort');
  String get s2SignalWeak => _t('Tín hiệu yếu', 'Weak', 'Signal faible');
  String get s2ConnectBtn => _t('Kết nối với cảm biến này', 'Connect to this sensor', 'Connecter ce capteur');
  String get s2Connecting => _t('Đang kết nối cảm biến…', 'Connecting…', 'Connexion…');
  String s2ConnectedTitle(String code) => _t(
        'Đã kết nối cảm biến $code',
        'Connected to sensor $code',
        'Connecté au capteur $code',
      );
  String get s2ConnectedLightCopy => _t(
        'Đèn trên cảm biến đã ổn định. Đang chuyển sang bước Wi-Fi…',
        'The light on the sensor is now solid blue.',
        'Le voyant du capteur est maintenant bleu fixe.',
      );
  String get s2NotFound => _t(
        'Chưa tìm thấy cảm biến vật lý nào. Hãy chắc chắn cảm biến đã cắm điện 5V và đứng gần dưới 2 mét.',
        "No physical sensor found yet. Make sure it's powered and you're within 2 metres.",
        'Aucun capteur physique détecté. Vérifiez l’alimentation et rapprochez-vous.',
      );
  String get s2SearchAgain => _t('Tìm lại cảm biến', 'Search again', 'Rechercher à nouveau');
  String get s2NotShowingLink => _t('Không thấy cảm biến?', 'Sensor not showing?', 'Capteur introuvable ?');
  String get s2HelpTitle => _t('Khắc phục khi không thấy cảm biến', 'Sensor not showing?', 'Capteur introuvable ?');
  String get s2HelpBody => _t(
        '1. Rút nguồn cảm biến ra rồi cắm lại (đảm bảo nguồn 5V ≥ 2A).\n2. Giữ nút cảm ứng (GPIO7) để kiểm tra phản hồi.\n3. Hoặc nhập thủ công mã ID thiết bị bên dưới để ghép nối qua mạng LAN.',
        '1. Unplug the sensor and plug it back in (5V ≥ 2A).\n2. Check the touch button (GPIO7).\n3. Or enter the sensor ID printed on the label below.',
        '1. Débranchez puis rebranchez le capteur (5V ≥ 2A).\n2. Vérifiez le bouton tactile (GPIO7).\n3. Ou saisissez manuellement l’ID inscrit sur l’étiquette.',
      );
  String get s2ManualIdLabel => _t('Mã ID trên nhãn thiết bị', 'Sensor ID on label', 'ID du capteur');
  String get s2UseManualId => _t('Dùng mã cảm biến này', 'Use this sensor ID', 'Utiliser cet ID');
  String get s2UseDemoSensor => _t('Chế độ thử nghiệm (cảm biến ảo)', 'Test mode (virtual sensor)', 'Mode test (capteur virtuel)');
  String get s2BtOffError => _t(
        'Không thể kết nối Bluetooth. Hãy kiểm tra Bluetooth đã bật và đứng gần cảm biến hơn.',
        'Bluetooth connection failed. Make sure Bluetooth is on and move closer.',
        'Échec Bluetooth. Vérifiez que le Bluetooth est activé et rapprochez-vous.',
      );

  // S3 Wi-Fi Setup
  String get s3Title => _t('Kết nối cảm biến với Wi-Fi', 'Connect the sensor to Wi-Fi', 'Connecter le capteur au Wi-Fi');
  String get s3Helper => _t(
        'Dùng Wi-Fi tại nhà nơi đặt cảm biến. Bắt buộc là mạng 2.4 GHz (ESP32-S3 chỉ hỗ trợ băng tần 2.4 GHz).',
        'Use the home Wi-Fi where the sensor is installed. Must be 2.4 GHz (ESP32-S3 supports 2.4 GHz only).',
        'Utilisez le Wi-Fi du domicile (bande 2,4 GHz obligatoire pour ESP32-S3).',
      );
  String get s3NetworksTitle => _t('Nhập hoặc chọn mạng Wi-Fi 2.4 GHz', 'Enter or pick a 2.4 GHz network', 'Réseau Wi-Fi 2,4 GHz');
  String get s3SsidLabel => _t('Tên mạng Wi-Fi (SSID 2.4 GHz) *', 'Wi-Fi network name (SSID 2.4 GHz) *', 'Nom du réseau Wi-Fi (2,4 GHz) *');
  String get s3SsidHint => _t('Nhập chính xác tên Wi-Fi tại nhà', 'Enter your home Wi-Fi name', 'Nom exact du réseau Wi-Fi');
  String get s3PasswordLabel => _t('Mật khẩu Wi-Fi', 'Wi-Fi password', 'Mot de passe Wi-Fi');
  String get s3PasswordHelper => _t('Phân biệt chữ hoa và chữ thường (để trống nếu mạng mở)', 'Case-sensitive (leave blank for open network)', 'Sensible à la casse');
  String get s3ConnectBtn => _t('Gửi cấu hình Wi-Fi tới cảm biến', 'Connect sensor to Wi-Fi', 'Connecter le capteur au Wi-Fi');
  String get s3NoWifiLink => _t('Nhà này không có Wi-Fi?', 'This home has no Wi-Fi', 'Ce domicile n’a pas de Wi-Fi');
  String get s3NoWifiBody => _t(
        'Cảm biến ESP32-S3 vẫn tự phát còi và bật đèn tại chỗ khi mất mạng. Để gửi cảnh báo đồng thời qua điện thoại/Telegram/SMS khi bạn đi xa, hãy lắp bộ phát Wi-Fi 4G (SIM di động) trong nhà.',
        'The ESP32-S3 still triggers room siren & light offline. For remote alerts, install a compact 4G mobile Wi-Fi router.',
        'L’alarme locale fonctionne hors ligne. Pour les alertes à distance, utilisez un routeur Wi-Fi 4G.',
      );
  String s3ProgressJoining(String ssid) => _t('Đang nạp cấu hình $ssid vào cảm biến', 'Sending $ssid to sensor', 'Envoi de $ssid au capteur');
  String get s3ProgressReaching => _t('Đang kết nối mạng gia đình', 'Connecting to home Wi-Fi', 'Connexion au Wi-Fi');
  String get s3ProgressDone => _t('Hoàn tất', 'Done', 'Terminé');
  String s3SuccessBanner(String ssid) => _t(
        'Cảm biến đã lưu cấu hình Wi-Fi "$ssid" và sẵn sàng hoạt động độc lập.',
        'Sensor saved "$ssid" and is ready to monitor independently.',
        'Le capteur a enregistré "$ssid" et fonctionne en autonomie.',
      );
  String s3WrongPassword(String ssid) => _t(
        'Không gửi được cấu hình "$ssid" tới cảm biến. Kiểm tra kết nối BLE và thử lại.',
        'Could not send "$ssid" to the sensor. Check BLE connection and try again.',
        'Impossible d’envoyer "$ssid" au capteur. Vérifiez le Bluetooth.',
      );
  String get s3SsidRequiredError => _t(
        'Vui lòng nhập tên mạng Wi-Fi 2.4 GHz.',
        'Please enter your 2.4 GHz Wi-Fi network name.',
        'Veuillez saisir le nom du réseau Wi-Fi 2,4 GHz.',
      );

  // S4 Name the room
  String get s4Title => _t('Cảm biến này đặt ở phòng nào?', 'Where is this sensor?', 'Où est placé ce capteur ?');
  String get s4RoomNameLabel => _t('Tên phòng *', 'Room name *', 'Nom de la pièce *');
  String get s4RoomNameHelper => _t(
        'Hiển thị trong tin nhắn & thông báo khẩn cấp. Ví dụ: Phòng tắm tầng 2.',
        'Shown in emergency alerts & SMS. Example: Upstairs bathroom.',
        'Affiché dans les alertes et SMS. Exemple : Salle de bain étage.',
      );
  String get s4PersonLabel => _t('Tên người thân được theo dõi *', 'Name of the person being monitored *', 'Nom de la personne suivie *');
  String get s4PersonPlaceholder => _t('Bắt buộc nhập (không để trống)', 'Required (cannot be empty)', 'Obligatoire');
  String get s4PersonHelper => _t(
        'Bắt buộc để tin nhắn & cuộc gọi khẩn cấp nêu rõ ai đang cần trợ giúp.',
        'Required so emergency SMS and alerts clearly identify who needs help.',
        'Obligatoire pour identifier clairement la personne dans les alertes.',
      );
  String get s4SaveBtn => _t('Lưu phòng này', 'Save room', 'Enregistrer la pièce');
  String get s4Saving => _t('Đang lưu…', 'Saving…', 'Enregistrement…');
  String s4SavedToast(String room) => _t('Đã lưu phòng "$room"', '$room saved', '$room enregistré');
  String get s4MissingError => _t(
        'Hãy chọn loại phòng hoặc nhập tên phòng.',
        'Choose a room type or enter a room name.',
        'Choisissez un type de pièce ou saisissez un nom.',
      );
  String get s4PersonRequiredError => _t(
        'Vui lòng nhập tên người thân được theo dõi (trường bắt buộc).',
        'Please enter the monitored person’s name (required).',
        'Veuillez saisir le nom de la personne suivie (obligatoire).',
      );
  String s4DuplicateError(String name) => _t(
        'Bạn đã có phòng tên "$name". Hãy thêm chi tiết, ví dụ "$name tầng 2".',
        "You already have a room called $name. Add a detail, like 'Upstairs $name'.",
        'Une pièce "$name" existe déjà. Ajoutez un détail, ex. "$name étage".',
      );

  // S5 Test the sensor
  String get s5Title => _t('Kiểm tra đảm bảo mọi thứ hoạt động', "Let's make sure it works", 'Vérifions que tout fonctionne');
  String get s5Check1Title => _t('Kiểm tra 1 – Nhận diện có người', 'Check 1 – Presence', 'Test 1 – Présence');
  String s5Check1Desc(String room) => _t(
        'Đi vào $room và đứng yên trong 5 giây.',
        'Walk into $room and stand still for 5 seconds.',
        'Entrez dans $room et restez immobile 5 secondes.',
      );
  String get s5WaitingMovement => _t('Đang chờ phát hiện chuyển động…', 'Waiting for movement…', 'En attente de mouvement…');
  String get s5PresenceOk => _t('Đã phát hiện có người trong phòng.', 'We can see someone in the room.', 'Présence détectée dans la pièce.');
  String get s5PresenceNotDone => _t('Chưa kiểm tra', 'Not done yet', 'Pas encore effectué');
  String get s5SimulatePresence => _t('Xác nhận đã đứng trong phòng', 'Confirm I am in the room', 'Confirmer ma présence');
  String get s5Check2Title => _t('Kiểm tra 2 – Cảnh báo & Còi đèn', 'Check 2 – Alert', 'Test 2 – Alerte');
  String get s5Check2Desc => _t(
        'Cảm biến sẽ nháy đèn, phát tiếng bíp và gửi thông báo thử về máy này. Người khác sẽ không bị làm phiền.',
        "We'll make the sensor light up and beep, and send an alert to this phone. Nobody else is alerted.",
        'Le capteur va clignoter, biper et envoyer un test sur ce téléphone. Personne d’autre n’est alerté.',
      );
  String get s5SoundMedium => _t('Âm lượng còi: Trung bình. Bạn có thể đổi lại sau.', 'Sound: medium. You can change this later.', 'Volume : moyen. Modifiable plus tard.');
  String get s5SendTestBtn => _t('Gửi cảnh báo thử', 'Send a test alert', 'Envoyer une alerte test');
  String get s5SendingTest => _t('Đang gửi thử…', 'Sending test…', 'Envoi du test…');
  String get s5StartMonitoring => _t('Bắt đầu giám sát', 'Start monitoring', 'Démarrer la surveillance');
  String s5ReadyBanner(String time, String room) => _t(
        'Đã nhận cảnh báo thử lúc $time. Phòng $room đã sẵn sàng.',
        'Test alert received at $time. $room is ready.',
        'Alerte test reçue à $time. $room est prêt.',
      );
  String get s5SkipLink => _t('Bỏ qua kiểm tra', 'Skip test', 'Passer le test');
  String get s5SkipConfirmTitle => _t('Bỏ qua bước kiểm tra?', 'Skip test?', 'Passer le test ?');
  String get s5SkipConfirmBody => _t(
        'Nếu không kiểm tra, bạn sẽ chưa chắc cảnh báo đã tới điện thoại. Vẫn bỏ qua?',
        "Without a test, you won't know if alerts reach you. Skip anyway?",
        'Sans test, vous ne saurez pas si les alertes arrivent bien. Passer quand même ?',
      );
  String get s5GoBackToTest => _t('Quay lại kiểm tra', 'Go back to test', 'Revenir au test');
  String get s5PresenceTimeout => _t(
        'Chưa thấy ai trong phòng. Kiểm tra xem cảm biến có bị che khuất không và đặt cao 1,5–2 m hướng vào phòng.',
        "We can't see anyone yet. Make sure nothing blocks the sensor and that it faces the room, 1.5–2 m high.",
        'Personne détecté. Vérifiez que rien n’obstrue le capteur (placé à 1,5–2 m).',
      );

  // S6 Home (neutral fallback if personName empty — NO hardcoded "Bà Lan"!)
  String s6HomeTitle(String person) {
    final trimmed = person.trim();
    if (trimmed.isEmpty) {
      return _t('Ngôi nhà của bạn', 'Your home', 'Votre domicile');
    }
    return _t('Nhà của $trimmed', "$trimmed's home", 'Maison de $trimmed');
  }
  String get s6MonitoringActive => _t('Đang giám sát', 'Monitoring active', 'Surveillance active');
  String get s6AttentionNeeded => _t('Cần chú ý', 'Attention needed', 'Attention requise');

  String get s6IncompleteProfileTitle => _t(
        'Chưa thiết lập tên người thân & liên hệ khẩn cấp',
        'Care profile incomplete',
        'Profil de suivi incomplet',
      );
  String get s6IncompleteProfileBody => _t(
        'Hãy điền tên người thân và ít nhất 1 số điện thoại cứu hộ để tin nhắn & cuộc gọi khẩn cấp hoạt động chính xác.',
        'Add the monitored person’s name and at least one emergency contact so alerts & SMS work accurately.',
        'Renseignez le nom du proche et au moins un contact d’urgence pour des alertes fiables.',
      );
  String get s6CompleteProfileBtn => _t('Thiết lập ngay', 'Set up now', 'Configurer maintenant');

  String s6AllGoodSummary(int count, String person, String room, String ago) => _t(
        'Đang giám sát $count phòng · Hoạt động gần nhất của ${personOrGeneric(person)} tại $room, $ago',
        'All $count rooms monitored · ${personOrGeneric(person)} last seen in $room, $ago',
        '$count pièces surveillées · Dernière activité de ${personOrGeneric(person)} dans $room, $ago',
      );
  String s6IssueSummary(String room) => _t(
        'Cảm biến $room đang ngoại tuyến · Không thể phát hiện té ngã tại đây',
        "$room sensor is offline · Falls can't be detected there",
        'Capteur $room hors ligne · Détection des chutes impossible',
      );
  String s6OfflineSince(String room, String time) => _t(
        'Cảm biến $room mất kết nối từ $time',
        '$room sensor offline since $time',
        'Capteur $room hors ligne depuis $time',
      );
  String get s6ReconnectSensor => _t('Kết nối lại cảm biến', 'Reconnect sensor', 'Reconnecter le capteur');
  String get s6AddRoom => _t('Thêm phòng mới', 'Add a room', 'Ajouter une pièce');
  String get s6EmptyTitle => _t('Chưa có cảm biến phòng nào', 'No room sensors yet', 'Aucun capteur installé');
  String s6EmptyBody(String person) => _t(
        'Bắt đầu bằng cách ghép nối cảm biến ESP32-S3 cho căn phòng nơi ${personOrGeneric(person)} hay ở nhất (phòng tắm, phòng ngủ hoặc phòng khách).',
        'Pair your first ESP32-S3 sensor for the room where ${personOrGeneric(person)} spends most time (bathroom, bedroom or living room).',
        'Ajoutez un premier capteur ESP32-S3 dans la pièce la plus fréquentée par ${personOrGeneric(person)}.',
      );
  String get s6StatusOccupied => _t('Đang có người', 'Someone here', 'Quelqu’un est là');
  String get s6StatusEmpty => _t('Phòng trống', 'Empty', 'Vide');
  String get s6StatusOffline => _t('Ngoại tuyến', 'Offline', 'Hors ligne');
  String s6MovementAgo(String ago) => _t('Có chuyển động $ago', 'Movement $ago', 'Mouvement $ago');
  String s6LastPresence(String time) => _t('Có người lúc $time', 'Last presence $time', 'Dernière présence à $time');
  String s6OfflineContext(String time) => _t(
        'Từ $time · Không thể phát hiện té ngã',
        "Since $time · Can't detect falls",
        'Depuis $time · Détection impossible',
      );
  String get s6SimulateFall => _t('Kiểm tra màn hình báo động té ngã (Thử nghiệm)', 'Test Fall Alert Screen', 'Tester l’écran d’alerte chute');
  String get s6OfflinePhoneBanner => _t(
        'Điện thoại đang ngoại tuyến. Đang hiển thị dữ liệu lưu cục bộ.',
        "You're offline. Showing locally cached data.",
        'Vous êtes hors ligne. Données en cache affichées.',
      );
  String get s6TodayActivity => _t('Hoạt động hôm nay', 'Activity today', 'Activité aujourd’hui');
  String get s6GuestModeActive => _t(
        'Chế độ Khách / Tạm dừng giám sát đang bật',
        'Guest / Privacy Pause mode is active',
        'Mode Invité / Pause confidentialité activé',
      );
  String get s6GuestModeResume => _t('Bật lại giám sát', 'Resume monitoring', 'Reprendre la surveillance');
  String get s6CheckInBtn => _t('Xác nhận đã hỏi thăm (An toàn)', 'Log Safe Check-In', 'Confirmer tout va bien');
  String s6LastCheckIn(String time) => _t('Đã hỏi thăm an toàn lúc $time', 'Safe check-in logged at $time', 'Vérifié en sécurité à $time');

  // S7 Fall Alert (Simultaneous Multi-Channel Broadcast!)
  String s7Title(String person) => _t(
        '${personOrGeneric(person)} có thể đã bị té ngã',
        '${personOrGeneric(person)} may have fallen',
        '${personOrGeneric(person)} a peut-être chuté',
      );
  String s7NoMovementSince(String time) => _t(
        'Không có chuyển động từ $time',
        'No movement since $time',
        'Aucun mouvement depuis $time',
      );
  String s7MovementAt(String time) => _t(
        'Phát hiện có cử động lúc $time (cảnh báo vẫn giữ mở)',
        'Movement detected at $time (alert remains open)',
        'Mouvement détecté à $time (alerte maintenue)',
      );
  String s7LightAlarmOn(String room) => _t(
        'Đèn sáng và còi báo động đang bật tại $room',
        'Light and alarm are on in $room',
        'La lumière et l’alarme sont activées dans $room',
      );
  String s7LightOnlyOn(String room) => _t(
        'Đã tắt còi, đèn chiếu sáng vẫn bật tại $room',
        'Buzzer muted; room light stays on in $room',
        'Sirène coupée ; la lumière reste allumée dans $room',
      );
  String s7SimultaneousBroadcast(int count) => _t(
        'Đang phát cảnh báo ĐỒNG THỜI tới cả $count người liên hệ (App · SMS · Telegram · Cuộc gọi)',
        'Broadcasting SIMULTANEOUSLY to all $count contacts (App · SMS · Telegram · Calls)',
        'Alerte SIMULTANÉE envoyée aux $count contacts (App · SMS · Telegram · Appels)',
      );
  String get s7SendGroupSms => _t('Gửi SMS khẩn cấp đồng loạt ngay', 'Send Emergency Group SMS Now', 'Envoyer un SMS groupé urgent');
  String get s7QuickCallFamily => _t('Gọi nhanh người thân cùng hỗ trợ', 'Quick-call family contacts', 'Appeler les proches');
  String s7EscalationCountdown(String contactName, String mmss) => _t(
        'Chế độ tuần tự: Nếu chưa phản hồi, sẽ báo $contactName sau $mmss',
        'Sequential mode: If no response, $contactName will be alerted in $mmss',
        'Mode séquentiel : sans réponse, $contactName sera alerté(e) dans $mmss',
      );
  String get s7EscalationNoBackup => _t(
        'Chưa có người thân dự phòng trong danh bạ — hãy thêm trong Cài đặt > Liên hệ khẩn cấp.',
        'No backup contacts configured yet — add family or neighbours in Alert Contacts.',
        'Aucun contact de secours configuré — ajoutez un proche dans Contacts d’alerte.',
      );
  String get s7PrimaryRespond => _t('Tôi đang xử lý (Nhận trách nhiệm)', "I'm responding (Claim alert)", 'J’interviens (Prendre en charge)');
  String s7RespondingStatus(String by) => _t(
        '$by đang xử lý sự cố này · Đã đồng bộ trạng thái cho toàn bộ nhóm gia đình',
        '$by is responding · All other family contacts have been notified',
        '$by intervient · Tous les autres proches ont été informés',
      );
  String get s7MarkResolved => _t('Đánh dấu đã xử lý xong', 'Mark as resolved', 'Marquer comme résolu');
  String get s7TurnOffRoomAlarm => _t('Tắt còi trong phòng', 'Turn off alarm in room', 'Couper la sirène');
  String s7CallPerson(String person) => _t('Gọi ${personOrGeneric(person)}', 'Call ${personOrGeneric(person)}', 'Appeler ${personOrGeneric(person)}');
  String s7CallEmergency(String number) => _t('Gọi cấp cứu $number', 'Call emergency ($number)', 'Urgences ($number)');
  String get s7FalseAlarmLink => _t('Đây là báo động giả', "It's a false alarm", 'C’est une fausse alerte');
  String get s7FalseAlarmTitle => _t('Xác nhận báo động giả & Chọn nguyên nhân', 'Mark as false alarm', 'Marquer comme fausse alerte');
  String s7FalseAlarmBody(String room) => _t(
        'Đèn báo động và còi tại $room sẽ tắt ngay. Ghi nhận nguyên nhân giúp bạn tinh chỉnh độ nhạy tốt hơn:',
        'Light and alarm in $room will turn off. Tagging the reason helps tune detection:',
        'La lumière et l’alarme dans $room s’éteindront. Indiquez la cause pour améliorer le réglage :',
      );
  String falseAlarmReasonLabel(FalseAlarmReason r) {
    switch (r) {
      case FalseAlarmReason.satDownQuickly:
        return _t('Ngồi xuống ghế/giường hơi nhanh', 'Sat down quickly', 'Assis(e) brusquement');
      case FalseAlarmReason.droppedObject:
        return _t('Làm rơi đồ vật lớn', 'Dropped an object', 'Objet tombé');
      case FalseAlarmReason.normalRoutine:
        return _t('Cúi nhặt đồ / sinh hoạt bình thường', 'Bending / routine movement', 'Mouvement habituel');
      case FalseAlarmReason.guestOrPet:
        return _t('Có khách hoặc thú cưng trong phòng', 'Guest or pet in room', 'Invité ou animal');
      case FalseAlarmReason.other:
        return _t('Nguyên nhân khác', 'Other reason', 'Autre cause');
    }
  }

  String get s7KeepAlertOpen => _t('Giữ cảnh báo mở', 'Keep alert open', 'Garder l’alerte ouverte');
  String get s7ResolveTitle => _t('Kết quả xử lý sự cố', 'How was this resolved?', 'Comment cela s’est-il résolu ?');
  String s7OutcomeOk(String person) => _t('${personOrGeneric(person)} vẫn ổn', '${personOrGeneric(person)} is OK', '${personOrGeneric(person)} va bien');
  String get s7OutcomeHelp => _t('Cần hỗ trợ y tế / đỡ dậy', 'Needed help', 'A eu besoin d’aide');
  String get s7OutcomeFalse => _t('Báo động giả', 'False alarm', 'Fausse alerte');
  String get s7OptionalNote => _t('Ghi chú thêm (không bắt buộc)', 'Optional note', 'Note facultative');
  String get s7DoorCodeLabel => _t('Mã khóa cửa / Địa chỉ nhà', 'Door code / Address', 'Code d’accès / Adresse');
  String get s7AckError => _t(
        'Điện thoại đang mất mạng nên chưa đồng bộ được cho người thân khác. Còi trong phòng vẫn bật.',
        'Phone appears offline; could not sync status to other contacts. Room alarm remains active.',
        'Téléphone hors ligne ; synchronisation impossible. L’alarme locale reste active.',
      );

  // S8 Room Detail & ESP32 Hardware Controls
  String s8OnlineHealth(String wifiQuality, String checkedAt) => _t(
        'Trực tuyến · Wi-Fi $wifiQuality · Kiểm tra lúc $checkedAt',
        'Online · Wi-Fi $wifiQuality · Last check $checkedAt',
        'En ligne · Wi-Fi $wifiQuality · Vérifié à $checkedAt',
      );
  String get s8WifiGood => _t('Tốt', 'Good', 'Bon');
  String get s8WifiFair => _t('Trung bình', 'Fair', 'Moyen');
  String get s8TestSensor => _t('Kiểm tra cảm biến này', 'Test this sensor', 'Tester ce capteur');
  String get s8TodayTimeline => _t('Nhật ký hôm nay', 'Today', 'Aujourd’hui');
  String get s8SeeEarlierDays => _t('Xem các ngày trước', 'See earlier days', 'Voir les jours précédents');
  String get s8NoEventsToday => _t(
        'Hôm nay chưa có sự kiện nào. Nhật ký sẽ xuất hiện khi có người ra vào phòng.',
        'Nothing has happened here yet today. Events appear when someone enters or leaves.',
        'Aucun événement aujourd’hui. Ils apparaîtront lors des passages.',
      );
  String get s8RoomSettings => _t('Cài đặt phòng & cảm biến', 'Room & sensor settings', 'Réglages de la pièce');
  String get s8AlarmVolume => _t('Âm thanh còi trong phòng', 'Alarm sound in room', 'Volume de l’alarme');
  String get s8NightLight => _t('Đèn ngủ thông minh khi có người vào', 'Night light when someone enters', 'Veilleuse automatique');
  String get s8InactivityAlert => _t('Cảnh báo ở quá lâu / bất động', 'Prolonged stay / inactivity alert', 'Alerte d’inactivité prolongée');
  String get s8AdjustDetection => _t('Tinh chỉnh độ nhạy & chiều cao sàn', 'Adjust detection', 'Ajuster la détection');
  String get s8AdjustDetectionSub => _t(
        'Chỉ thay đổi nếu gặp báo động giả (hiệu chuẩn sàn, còi, cảm biến)',
        'Change only if you get false alarms',
        'À modifier uniquement en cas de fausses alertes',
      );
  String get s8LiveHardwareTitle => _t('Dữ liệu cảm biến trực tiếp (ESP32-S3)', 'Live sensor insights (ESP32-S3)', 'Télémétrie capteur en direct');
  String get s8LiveHardwareSub => _t(
        'Chiều cao ToF, Radar 24GHz, tư thế AI & điều khiển phần cứng',
        'ToF height, 24GHz Radar, AI posture & hardware controls',
        'Hauteur ToF, Radar 24GHz, posture IA et contrôles',
      );
  String get s8RemoteChannels => _t('Kênh cảnh báo từ xa (Telegram & SMS)', 'Remote alert channels (Telegram & SMS)', 'Canaux distants (Telegram & SMS)');
  String get s8FirmwareOta => _t('Cập nhật Firmware OTA (ESP32-S3)', 'Firmware OTA update', 'Mise à jour Firmware OTA');
  String get s8BlackboxHistory => _t('Hộp đen NVS Flash (5 sự cố gần nhất)', 'NVS Flash Blackbox (last 5 events)', 'Boîte noire NVS (5 derniers événements)');
  String get s8CalibrateFloor => _t('Hiệu chuẩn mặt sàn', 'Calibrate floor', 'Calibrer le sol');
  String get s8TriggerSos => _t('Kích hoạt SOS khẩn cấp', 'Trigger remote SOS', 'Déclencher SOS');
  String get s8RenameRoom => _t('Đổi tên phòng', 'Rename room', 'Renommer la pièce');
  String get s8RemoveRoom => _t('Xóa phòng này', 'Remove room', 'Supprimer la pièce');
  String get s8Maintenance => _t('Bảo trì & Khởi động lại thiết bị', 'Device reboot & reset', 'Maintenance & réinitialisation');

  // S9 Alert Contacts (Simultaneous Default + Multi-Channel)
  String get s9AlmostDone => _t('Sắp xong', 'Almost done', 'Presque terminé');
  String get s9Title => _t('Liên hệ & Kênh cảnh báo khẩn cấp', 'Alert contacts & channels', 'Contacts & canaux d’alerte');
  String get s9ModeTitle => _t('Phương thức phát cảnh báo khi phát hiện té ngã', 'Alert dispatch mode', 'Mode d’envoi des alertes');
  String get s9ModeSimultaneous => _t('Đồng thời tất cả (Khuyên dùng)', 'Simultaneous to all (Recommended)', 'Simultané à tous (Recommandé)');
  String get s9ModeSequential => _t('Tuần tự từng người', 'Sequential order', 'Séquentiel un par un');
  String get s9SimultaneousExplainer => _t(
        'Khi có té ngã, hệ thống gửi thông báo App, tin nhắn SMS, Telegram và mở gọi nhanh ĐỒNG THỜI tới toàn bộ người liên hệ trong danh sách để rút ngắn tối đa thời gian cấp cứu.',
        'On a fall, App alert, SMS, Telegram and quick-call options trigger SIMULTANEOUSLY for every contact so no critical minute is lost.',
        'En cas de chute, App, SMS, Telegram et appels rapides sont déclenchés SIMULTANÉMENT pour tous les contacts.',
      );
  String s9SequentialExplainer(int minutes) => _t(
        'Nếu người trước không phản hồi sau $minutes phút, hệ thống sẽ chuyển cảnh báo sang người tiếp theo.',
        "If the first contact doesn't respond within $minutes minutes, the next person is alerted.",
        'Sans réponse sous $minutes min, la personne suivante est alertée.',
      );
  String get s9AddContact => _t('Thêm người liên hệ khẩn cấp', 'Add emergency contact', 'Ajouter un contact d’urgence');
  String get s9AddLater => _t('Thêm sau', 'Add later', 'Ajouter plus tard');
  String get s9WaitBeforeNext => _t('Thời gian chờ (chế độ tuần tự)', 'Wait before next person (sequential)', 'Délai avant escalade');
  String s9Minutes(int m) => _t('$m phút', '$m min', '$m min');
  String get s9EmptyHint => _t(
        'Hiện chỉ có mình bạn nhận cảnh báo. Hãy thêm ít nhất 1 người thân hoặc hàng xóm ở gần để nhận SMS, Telegram và cuộc gọi đồng thời khi có sự cố.',
        'Right now only you receive alerts. Add at least one family member or nearby neighbour for simultaneous SMS, Telegram & call backup.',
        'Vous seul(e) recevez les alertes. Ajoutez au moins un proche ou voisin pour un relais simultané.',
      );
  String get s9ContactName => _t('Họ và tên *', 'Full name *', 'Nom complet *');
  String get s9ContactPhone => _t('Số điện thoại di động *', 'Mobile number *', 'Numéro de mobile *');
  String get s9InviteHelper => _t(
        'Số này sẽ được đồng bộ trực tiếp vào ESP32-S3 để gửi SMS cứu hộ tự động và mở gọi nhanh trên S7.',
        'Synced directly to ESP32-S3 for automatic SMS gateway alerts and one-tap S7 calls.',
        'Synchronisé avec l’ESP32-S3 pour les SMS d’urgence et les appels rapides.',
      );
  String get s9SendInvite => _t('Lưu & Đồng bộ liên hệ', 'Save & Sync contact', 'Enregistrer & Synchroniser');
  String get s9PhoneError => _t(
        'Số điện thoại chưa hợp lệ (cần ít nhất 9 chữ số).',
        'Please enter a valid mobile number (at least 9 digits).',
        'Numéro invalide (au moins 9 chiffres).',
      );
  String get s9BadgeJoined => _t('Sẵn sàng nhận tin', 'Active', 'Actif');
  String get s9BadgeInvited => _t('Đã đồng bộ SMS', 'SMS synced', 'SMS synchronisé');
  String get s9YouThisPhone => _t('Bạn · Điện thoại này', 'You · this phone', 'Vous · ce téléphone');
  String get s9MoveUp => _t('Đưa lên', 'Move up', 'Monter');
  String get s9MoveDown => _t('Đưa xuống', 'Move down', 'Descendre');

  // Medical, Medication, Guest Mode & Safety tools
  String get medicalSuiteTitle => _t('Chăm sóc, Nhắc thuốc & Y tế khẩn cấp', 'Elderly Care, Meds & Medical Kit', 'Soins, Médicaments & Kit Médical');
  String get firstAidTitle => _t('Hướng dẫn sơ cứu té ngã', 'Fall First Aid Guide', 'Premiers secours chute');
  String get firstAidSub => _t('4 bước chuẩn y khoa khi phát hiện người già ngã', '4 step-by-step clinical instructions', '4 étapes cliniques illustrées');
  String get medicalIdTitle => _t('Thẻ Hồ sơ Y tế & Mã mở cửa', 'Emergency Medical ID & Door Access', 'Fiche médicale & Code d’accès');
  String get medicalIdSub => _t('Nhóm máu, bệnh nền, thuốc, địa chỉ & mã khóa cửa', 'Blood type, conditions, meds, address & lockbox', 'Groupe sanguin, traitements, adresse & code');
  String get medicationTitle => _t('Lịch nhắc uống thuốc hằng ngày', 'Daily Medication Schedule', 'Rappels de médicaments');
  String get medicationSub => _t('Theo dõi cữ thuốc kết hợp trạng thái hiện diện trong nhà', 'Track daily doses alongside home presence', 'Suivi des prises avec détection de présence');
  String get steadiTitle => _t('Đánh giá nguy cơ té ngã CDC STEADI', 'CDC STEADI Fall Risk Check', 'Évaluation risque de chute STEADI');
  String get steadiSub => _t('Bộ câu hỏi tầm soát nguy cơ ngã cho người cao tuổi', '12-point clinical fall risk screening', 'Questionnaire clinique en 12 points');
  String get auditReportTitle => _t('Báo cáo kiểm tra y tế tổng hợp', 'Medical Safety Audit Report', 'Rapport de sécurité médicale');
  String get auditReportSub => _t('Tổng hợp chỉ số STEADI, lịch sử sự cố & sức khỏe cảm biến', 'Combined STEADI score, incidents & sensor health', 'Synthèse STEADI, incidents et capteurs');
  String get guestModeTitle => _t('Chế độ Khách / Tạm dừng giám sát', 'Guest / Privacy Pause Mode', 'Mode Invité / Pause confidentialité');
  String get guestModeSub => _t('Tạm tắt báo động tự động khi có khách hoặc dọn nhà', 'Temporarily pause automated alerts when guests visit', 'Mettre en pause les alertes lors de visites');
  String get appUpdatesTitle => _t('Kiểm tra cập nhật App & Firmware', 'Check App & Firmware Updates', 'Vérifier les mises à jour');
  String get emergencyNumberLabel => _t('Số điện thoại cấp cứu khu vực', 'Emergency services number', 'Numéro des urgences');

  // Event labels
  String eventTitle(HearthEvent e, String personName) {
    switch (e.type) {
      case HearthEventType.entered:
        return _t('Có người vào phòng', 'Someone entered', 'Entrée détectée');
      case HearthEventType.left:
        return _t('Phòng trống', 'Room empty', 'Pièce vide');
      case HearthEventType.fallDetected:
        return _t('Phát hiện nghi ngờ té ngã', 'Possible fall detected', 'Chute possible détectée');
      case HearthEventType.fallResolved:
        final by = e.resolvedBy ?? _t('người chăm sóc', 'carer', 'aidant');
        return _t(
          'Đã xử lý cảnh báo bởi $by',
          'Fall alert resolved by $by',
          'Alerte résolue par $by',
        );
      case HearthEventType.sensorOffline:
        return _t('Cảm biến mất kết nối', 'Sensor went offline', 'Capteur hors ligne');
      case HearthEventType.testPassed:
        return _t('Kiểm tra cảm biến thành công', 'Sensor test passed', 'Test du capteur réussi');
      case HearthEventType.manualSos:
        return _t('Kích hoạt SOS thủ công', 'Manual SOS triggered', 'SOS manuel déclenché');
      case HearthEventType.inactivityWarning:
        return _t('Cảnh báo bất động / ở quá lâu trong phòng', 'Prolonged inactivity warning', 'Alerte d’inactivité prolongée');
      case HearthEventType.safeCheckIn:
        return _t('Xác nhận đã hỏi thăm an toàn', 'Safe check-in logged', 'Contrôle de sécurité confirmé');
    }
  }

  String outcomeLabel(FallResolutionOutcome o, String personName) {
    switch (o) {
      case FallResolutionOutcome.personOk:
        return s7OutcomeOk(personName);
      case FallResolutionOutcome.neededHelp:
        return s7OutcomeHelp;
      case FallResolutionOutcome.falseAlarm:
        return s7OutcomeFalse;
    }
  }

  String soundLevelLabel(AlarmSoundLevel level) {
    switch (level) {
      case AlarmSoundLevel.mute:
        return _t('Tắt tiếng (Mute)', 'Muted', 'Muet');
      case AlarmSoundLevel.low:
        return _t('Nhẹ', 'Low', 'Faible');
      case AlarmSoundLevel.medium:
        return _t('Trung bình', 'Medium', 'Moyen');
      case AlarmSoundLevel.high:
        return _t('Lớn', 'High', 'Fort');
    }
  }

  String formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 45) return _t('vừa xong', 'just now', 'à l’instant');
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return _t('$m phút trước', '$m min ago', 'il y a $m min');
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return _t('$h giờ trước', '$h hr ago', 'il y a $h h');
    }
    final d = diff.inDays;
    return _t('$d ngày trước', '$d d ago', 'il y a $d j');
  }

  String formatClock(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
