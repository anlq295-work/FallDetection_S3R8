import '../core/models.dart';

/// Complete tri-lingual dictionary: Vietnamese (default), English, French.
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
  String stepOf(int step, int total) => _t(
        'Bước $step / $total',
        'Step $step of $total',
        'Étape $step sur $total',
      );

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

  // S1 Welcome & Sign In
  String get s1Headline => _t(
        'An tâm biết người thân an toàn ở nhà, ngay cả khi bạn đi xa.',
        "Know they're safe at home, even when you're away.",
        'Sachez vos proches en sécurité à la maison, même à distance.',
      );
  String get s1Fact1 => _t(
        'Phát hiện té ngã không cần camera',
        'Detects falls without cameras',
        'Détecte les chutes sans caméra',
      );
  String get s1Fact2 => _t(
        'Báo về điện thoại và bật đèn sáng trong phòng',
        'Alerts your phone and lights up the room',
        'Alerte votre téléphone et éclaire la pièce',
      );
  String get s1Fact3 => _t(
        'Hoạt động qua Wi-Fi gia đình 2.4 GHz',
        'Works over your home Wi-Fi',
        'Fonctionne via le Wi-Fi domestique',
      );
  String get s1EmailLabel => _t('Địa chỉ email', 'Email address', 'Adresse e-mail');
  String get s1EmailPlaceholder => 'anna.ruiz@mail.com';
  String get s1EmailHelper => _t(
        'Chúng tôi sẽ gửi mã 6 chữ số. Không cần nhớ mật khẩu.',
        "We'll send you a 6-digit code. No password needed.",
        'Nous vous enverrons un code à 6 chiffres. Aucun mot de passe requis.',
      );
  String get s1SendCode => _t('Gửi mã đăng nhập cho tôi', 'Send me a sign-in code', 'M’envoyer un code de connexion');
  String get s1SendingCode => _t('Đang gửi mã…', 'Sending code…', 'Envoi du code…');
  String get s1AlreadyHaveCode => _t('Tôi đã có mã đăng nhập', 'I already have a code', 'J’ai déjà un code');
  String get s1Legal => _t(
        'Khi tiếp tục, bạn đồng ý với Điều khoản sử dụng và Chính sách bảo mật.',
        'By continuing you agree to the Terms and Privacy notice.',
        'En continuant, vous acceptez les Conditions et la Politique de confidentialité.',
      );
  String get s1CodeLabel => _t('Mã xác nhận 6 chữ số', '6-digit sign-in code', 'Code à 6 chiffres');
  String s1CodeSentTo(String email) => _t(
        'Đã gửi mã tới $email (Mã thử nghiệm: 123456)',
        'Code sent to $email (Demo code: 123456)',
        'Code envoyé à $email (Code démo : 123456)',
      );
  String get s1SignIn => _t('Đăng nhập', 'Sign in', 'Se connecter');
  String get s1SigningIn => _t('Đang xác thực…', 'Signing in…', 'Connexion…');
  String s1ResendCountdown(int sec) => _t(
        'Gửi lại mã mới (sau 0:${sec.toString().padLeft(2, '0')})',
        'Send a new code (available in 0:${sec.toString().padLeft(2, '0')})',
        'Renvoyer un code (dans 0:${sec.toString().padLeft(2, '0')})',
      );
  String get s1ResendNow => _t('Gửi mã mới', 'Send a new code', 'Envoyer un nouveau code');
  String get s1EmailError => _t(
        'Email có vẻ chưa đầy đủ. Hãy kiểm tra ký tự @ và tên miền, ví dụ name@mail.com.',
        'That email looks incomplete. Check it has an @ and a domain, like name@mail.com.',
        'Cet e-mail semble incomplet. Vérifiez qu’il contient @ et un domaine, comme nom@mail.com.',
      );
  String get s1CodeError => _t(
        'Mã không khớp hoặc đã hết hạn. Kiểm tra email mới nhất hoặc gửi lại mã mới.',
        "That code didn't match or has expired. Check the latest email or send a new code.",
        'Ce code est incorrect ou expiré. Vérifiez votre dernier e-mail ou demandez un nouveau code.',
      );
  String get s1NetworkError => _t(
        'Không có kết nối mạng. Hãy bật Wi-Fi hoặc dữ liệu di động rồi thử lại.',
        'No internet connection. Connect to Wi-Fi or mobile data and try again.',
        'Aucune connexion Internet. Activez le Wi-Fi ou les données mobiles puis réessayez.',
      );
  String get s1SetupIntro => _t(
        'Hãy cài đặt cảm biến đầu tiên (mất khoảng 5–10 phút). Cắm điện cảm biến và chuẩn bị sẵn mật khẩu Wi-Fi.',
        "Let's set up your first sensor. It takes about 10 minutes. Have the sensor plugged in and your Wi-Fi password ready.",
        'Configurons votre premier capteur (environ 10 min). Branchez-le et préparez votre mot de passe Wi-Fi.',
      );
  String get s1DesktopHint => _t(
        'Cài đặt lần đầu cần Bluetooth trên điện thoại. Sau khi hoàn tất, bạn có thể theo dõi từ mọi thiết bị.',
        'Setup needs your phone (Bluetooth). You can watch from here afterwards.',
        'La configuration nécessite le Bluetooth du téléphone. Vous pourrez ensuite suivre depuis cet écran.',
      );
  String get s1ReturningSkip => _t('Đã thiết lập trước đó? Vào Trang chủ', 'Already set up? Go to Home', 'Déjà configuré ? Aller à l’accueil');

  // S2 Find Sensor
  String get s2Title => _t('Tìm cảm biến của bạn', 'Find your sensor', 'Trouver votre capteur');
  String get s2Step1 => _t(
        'Cắm nguồn cảm biến vào ổ điện trong phòng cần theo dõi.',
        'Plug the sensor into a socket in the room you want to watch.',
        'Branchez le capteur sur une prise dans la pièce à surveiller.',
      );
  String get s2Step2 => _t(
        'Đợi đèn trên hộp cảm biến chuyển sang trạng thái sẵn sàng (khoảng 10 giây).',
        'Wait until the light blinks blue (about 10 seconds).',
        'Attendez que le voyant clignote en bleu (environ 10 secondes).',
      );
  String get s2Step3 => _t(
        'Giữ điện thoại trong phạm vi 2 mét gần cảm biến.',
        'Keep your phone within 2 metres.',
        'Gardez votre téléphone à moins de 2 mètres.',
      );
  String get s2PermissionTitle => _t(
        'Hearth chỉ dùng Bluetooth cho lần cài đặt cảm biến đầu tiên.',
        'Hearth uses Bluetooth only to set up the sensor the first time.',
        'Hearth utilise le Bluetooth uniquement lors de la première installation.',
      );
  String get s2AllowBluetooth => _t('Cho phép Bluetooth', 'Allow Bluetooth', 'Autoriser le Bluetooth');
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
        'Chưa tìm thấy cảm biến nào. Hãy chắc chắn cảm biến đã cắm điện và bạn đứng đủ gần.',
        "No sensor found yet. Make sure the light is blinking blue and you're close to it.",
        'Aucun capteur trouvé. Vérifiez que le voyant clignote en bleu et rapprochez-vous.',
      );
  String get s2SearchAgain => _t('Tìm lại cảm biến', 'Search again', 'Rechercher à nouveau');
  String get s2NotShowingLink => _t('Không thấy cảm biến?', 'Sensor not showing?', 'Capteur introuvable ?');
  String get s2HelpTitle => _t('Khắc phục khi không thấy cảm biến', 'Sensor not showing?', 'Capteur introuvable ?');
  String get s2HelpBody => _t(
        '1. Rút nguồn cảm biến ra rồi cắm lại.\n2. Giữ nút cảm ứng (GPIO7) trong 5 giây hoặc kiểm tra nguồn 5V 2A.\n3. Hoặc nhập thủ công mã ID in trên nhãn thiết bị bên dưới.',
        '1. Unplug the sensor and plug it back in.\n2. Hold the device button for 5 seconds to reset.\n3. Or enter the sensor ID printed on the label below.',
        '1. Débranchez puis rebranchez le capteur.\n2. Maintenez le bouton pendant 5 s pour réinitialiser.\n3. Ou saisissez manuellement l’ID inscrit sur l’étiquette.',
      );
  String get s2ManualIdLabel => _t('Mã ID trên nhãn thiết bị', 'Sensor ID on label', 'ID du capteur');
  String get s2UseManualId => _t('Dùng mã cảm biến này', 'Use this sensor ID', 'Utiliser cet ID');
  String get s2UseDemoSensor => _t('Dùng cảm biến mô phỏng (không cần phần cứng)', 'Use simulated sensor (demo)', 'Utiliser un capteur simulé (démo)');
  String get s2BtOffError => _t(
        'Bluetooth đang tắt. Hãy bật Bluetooth trong Cài đặt điện thoại rồi quay lại.',
        'Bluetooth is off. Turn it on in your phone settings, then come back.',
        'Le Bluetooth est désactivé. Activez-le dans les réglages puis revenez.',
      );
  String get s2DesktopTitle => _t(
        'Cài đặt cảm biến bằng điện thoại của bạn',
        'Set up sensors from your phone',
        'Configurez les capteurs depuis votre téléphone',
      );

  // S3 Wi-Fi Setup
  String get s3Title => _t('Kết nối cảm biến với Wi-Fi', 'Connect the sensor to Wi-Fi', 'Connecter le capteur au Wi-Fi');
  String get s3Helper => _t(
        'Dùng Wi-Fi tại nhà nơi đặt cảm biến. Bắt buộc là mạng 2.4 GHz (hầu hết router gia đình đều có).',
        'Use the Wi-Fi of the home where the sensor is. It must be a 2.4 GHz network (most home routers have one).',
        'Utilisez le Wi-Fi du domicile. Il doit s’agir d’un réseau 2,4 GHz (présent sur la plupart des box).',
      );
  String get s3NetworksTitle => _t('Mạng Wi-Fi 2.4 GHz khả dụng', 'Networks the sensor can see', 'Réseaux détectés par le capteur');
  String get s3ScanningNetworks => _t('Cảm biến đang quét các mạng Wi-Fi…', 'The sensor is looking for networks…', 'Le capteur recherche les réseaux…');
  String get s3ManualNetwork => _t('Nhập tên mạng Wi-Fi thủ công', 'Enter network name manually', 'Saisir le nom du réseau manuellement');
  String get s3SsidLabel => _t('Tên mạng Wi-Fi (SSID 2.4 GHz)', 'Wi-Fi network name (2.4 GHz)', 'Nom du réseau Wi-Fi (2,4 GHz)');
  String get s3PasswordLabel => _t('Mật khẩu Wi-Fi', 'Wi-Fi password', 'Mot de passe Wi-Fi');
  String get s3PasswordHelper => _t('Phân biệt chữ hoa và chữ thường', 'Case-sensitive', 'Sensible à la casse');
  String get s3ConnectBtn => _t('Kết nối cảm biến với Wi-Fi', 'Connect sensor to Wi-Fi', 'Connecter le capteur au Wi-Fi');
  String get s3NoWifiLink => _t('Nhà này không có Wi-Fi?', 'This home has no Wi-Fi', 'Ce domicile n’a pas de Wi-Fi');
  String get s3NoWifiBody => _t(
        'Cảm biến ESP32-S3 vẫn tự phát còi và bật đèn tại chỗ khi mất mạng. Để gửi cảnh báo từ xa qua điện thoại/Telegram/SMS, bạn có thể lắp thêm bộ phát Wi-Fi 4G (SIM di động) trong nhà.',
        'The sensor still sounds the room alarm offline. To alert you remotely, use a compact 4G mobile broadband Wi-Fi router in the home.',
        'L’alarme locale fonctionne hors ligne. Pour recevoir les alertes à distance, utilisez un routeur Wi-Fi 4G.',
      );
  String s3ProgressJoining(String ssid) => _t('Đang vào mạng $ssid', 'Joining $ssid', 'Connexion à $ssid');
  String get s3ProgressReaching => _t('Đang kết nối Hearth', 'Reaching Hearth', 'Connexion à Hearth');
  String get s3ProgressDone => _t('Hoàn tất', 'Done', 'Terminé');
  String s3SuccessBanner(String ssid) => _t(
        'Cảm biến đã trực tuyến trên $ssid. Bạn sẽ không cần Bluetooth cho cảm biến này nữa.',
        "Sensor is online on $ssid. You won't need Bluetooth again for this sensor.",
        'Le capteur est en ligne sur $ssid. Vous n’aurez plus besoin du Bluetooth pour ce capteur.',
      );
  String s3WrongPassword(String ssid) => _t(
        'Cảm biến không vào được mạng $ssid. Có thể mật khẩu bị sai — hãy kiểm tra chữ hoa/thường và thử lại.',
        "The sensor couldn't join $ssid. The password may be wrong. Check upper and lower case and try again.",
        'Impossible de rejoindre $ssid. Vérifiez les majuscules/minuscules du mot de passe.',
      );
  String get s3NoNetworksError => _t(
        'Cảm biến không thấy mạng Wi-Fi 2.4 GHz nào. Hãy đưa router lại gần hoặc bật băng tần 2.4 GHz.',
        "The sensor can't see any 2.4 GHz Wi-Fi. Move the router closer or check that 2.4 GHz is turned on.",
        'Aucun réseau 2,4 GHz détecté. Rapprochez la box ou activez la bande 2,4 GHz.',
      );

  // S4 Name the room
  String get s4Title => _t('Cảm biến này đặt ở phòng nào?', 'Where is this sensor?', 'Où est placé ce capteur ?');
  String get s4RoomNameLabel => _t('Tên phòng', 'Room name', 'Nom de la pièce');
  String get s4RoomNameHelper => _t(
        'Hiển thị trong thông báo khẩn cấp. Ví dụ: Phòng tắm tầng 2.',
        'Shown in alerts. Example: Upstairs bathroom.',
        'Affiché dans les alertes. Exemple : Salle de bain étage.',
      );
  String get s4PersonLabel => _t('Tên người thân bạn đang chăm sóc', "Name of the person you're looking after", 'Prénom de la personne accompagnée');
  String get s4PersonPlaceholder => _t('Ví dụ: Bà Lan', 'Example: Margaret', 'Exemple : Marguerite');
  String get s4PersonHelper => _t(
        'Dùng trong thông báo để biết ngay ai đang cần giúp đỡ.',
        'Used in alerts so you know who needs help.',
        'Utilisé dans les alertes pour savoir qui a besoin d’aide.',
      );
  String get s4SaveBtn => _t('Lưu phòng này', 'Save room', 'Enregistrer la pièce');
  String get s4Saving => _t('Đang lưu…', 'Saving…', 'Enregistrement…');
  String s4SavedToast(String room) => _t('Đã lưu phòng "$room"', '$room saved', '$room enregistré');
  String get s4MissingError => _t(
        'Hãy chọn loại phòng hoặc nhập tên phòng.',
        'Choose a room type or enter a room name.',
        'Choisissez un type de pièce ou saisissez un nom.',
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

  // S6 Home
  String s6HomeTitle(String person) => _t('Nhà của $person', "$person's home", 'Maison de $person');
  String s6AllGoodSummary(int count, String person, String room, String ago) => _t(
        'Đang giám sát cả $count phòng · Thấy $person gần nhất tại $room, $ago',
        'All $count rooms monitored · $person was last seen in $room, $ago',
        'Les $count pièces sont surveillées · $person vu(e) dans $room, $ago',
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
  String get s6EmptyTitle => _t('Chưa có phòng nào', 'No rooms yet', 'Aucune pièce pour le moment');
  String s6EmptyBody(String person) => _t(
        'Hãy thêm căn phòng nơi $person dành nhiều thời gian nhất trước, như phòng khách hoặc phòng tắm.',
        'Add the room where $person spends most time first, like the living room or bathroom.',
        'Ajoutez d’abord la pièce où $person passe le plus de temps, comme le salon ou la salle de bain.',
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
  String get s6SimulateFall => _t('Mô phỏng té ngã (Thử nghiệm)', 'Simulate fall in Bathroom', 'Simuler une chute (Test)');
  String get s6OfflinePhoneBanner => _t(
        'Điện thoại đang ngoại tuyến. Đang hiển thị dữ liệu gần nhất.',
        "You're offline. Showing cached data.",
        'Vous êtes hors ligne. Données en cache affichées.',
      );
  String get s6TodayActivity => _t('Hoạt động hôm nay', 'Activity today', 'Activité aujourd’hui');

  // S7 Fall Alert
  String s7Title(String person) => _t(
        '$person có thể đã bị té ngã',
        '$person may have fallen',
        '$person a peut-être chuté',
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
  String s7EscalationCountdown(String contactName, String mmss) => _t(
        'Nếu không ai phản hồi, hệ thống sẽ báo cho $contactName sau $mmss',
        'If nobody responds, $contactName will be alerted in $mmss',
        'Sans réponse, $contactName sera alerté(e) dans $mmss',
      );
  String get s7EscalationNoBackup => _t(
        'Chưa có người dự phòng — bạn là người nhận duy nhất.',
        'No backup contact configured yet.',
        'Aucun contact de secours configuré.',
      );
  String get s7PrimaryRespond => _t('Tôi đang xử lý', "I'm responding", 'J’interviens');
  String s7RespondingStatus(String? backup) => backup != null
      ? _t(
          'Bạn đang xử lý · Đã thông báo cho $backup',
          "You're responding · $backup has been told",
          'Vous intervenez · $backup a été prévenu(e)',
        )
      : _t('Bạn đang xử lý sự cố này', "You're responding", 'Vous intervenez');
  String get s7MarkResolved => _t('Đánh dấu đã xử lý xong', 'Mark as resolved', 'Marquer comme résolu');
  String get s7TurnOffRoomAlarm => _t('Tắt còi trong phòng', 'Turn off alarm in room', 'Couper la sirène');
  String s7CallPerson(String person) => _t('Gọi $person', 'Call $person', 'Appeler $person');
  String s7CallEmergency(String number) => _t('Gọi cấp cứu $number', 'Call emergency ($number)', 'Urgences ($number)');
  String get s7FalseAlarmLink => _t('Đây là báo động giả', "It's a false alarm", 'C’est une fausse alerte');
  String get s7FalseAlarmTitle => _t('Xác nhận báo động giả?', 'Mark as false alarm?', 'Marquer comme fausse alerte ?');
  String s7FalseAlarmBody(String room) => _t(
        'Đèn báo động và còi tại $room sẽ tắt ngay lập tức.',
        'The light and alarm in $room will turn off.',
        'La lumière et l’alarme dans $room s’éteindront.',
      );
  String get s7KeepAlertOpen => _t('Giữ cảnh báo mở', 'Keep alert open', 'Garder l’alerte ouverte');
  String get s7ResolveTitle => _t('Kết quả xử lý sự cố', 'How was this resolved?', 'Comment cela s’est-il résolu ?');
  String s7OutcomeOk(String person) => _t('$person vẫn ổn', '$person is OK', '$person va bien');
  String get s7OutcomeHelp => _t('Cần hỗ trợ y tế / đỡ dậy', 'Needed help', 'A eu besoin d’aide');
  String get s7OutcomeFalse => _t('Báo động giả', 'False alarm', 'Fausse alerte');
  String get s7OptionalNote => _t('Ghi chú thêm (không bắt buộc)', 'Optional note', 'Note facultative');
  String s7AckError(String backup) => _t(
        'Chưa thể báo cho $backup do điện thoại mất mạng. Còi trong phòng vẫn đang kêu.',
        "We couldn't tell $backup you're responding. Your phone seems offline. The alarm is still on.",
        'Impossible de prévenir $backup (hors ligne). L’alarme reste active.',
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

  // S9 Alert Contacts
  String get s9AlmostDone => _t('Sắp xong', 'Almost done', 'Presque terminé');
  String get s9Title => _t('Ai sẽ cùng nhận cảnh báo?', 'Who else should be alerted?', 'Qui d’autre doit être alerté ?');
  String s9Explainer(int minutes) => _t(
        'Nếu bạn không phản hồi sau $minutes phút, người tiếp theo trong danh sách sẽ nhận cảnh báo.',
        "If you don't respond within $minutes minutes, the next person is alerted.",
        'Sans réponse de votre part sous $minutes min, la personne suivante est alertée.',
      );
  String get s9AddContact => _t('Thêm người liên hệ', 'Add a contact', 'Ajouter un contact');
  String get s9AddLater => _t('Thêm sau', 'Add later', 'Ajouter plus tard');
  String get s9WaitBeforeNext => _t('Thời gian chờ trước khi chuyển người kế tiếp', 'Wait before alerting the next person', 'Délai avant escalade');
  String s9Minutes(int m) => _t('$m phút', '$m min', '$m min');
  String get s9EmptyHint => _t(
        'Hiện chỉ có mình bạn nhận cảnh báo. Hãy thêm người thân hoặc hàng xóm ở gần để dự phòng.',
        'Right now, only you get alerts. Add a neighbour or relative who lives nearby as a backup.',
        'Actuellement vous seul(e) recevez les alertes. Ajoutez un proche ou voisin en secours.',
      );
  String get s9ContactName => _t('Họ và tên', 'Name', 'Nom');
  String get s9ContactPhone => _t('Số điện thoại di động', 'Mobile number', 'Numéro de mobile');
  String get s9InviteHelper => _t(
        'Chúng tôi sẽ gửi lời mời cài Hearth và đồng bộ số này vào danh bạ cứu hộ của cảm biến.',
        "We'll text them an invite to install Hearth and sync emergency SMS to the sensor.",
        'Nous leur enverrons une invitation Hearth et synchroniserons le numéro avec le capteur.',
      );
  String get s9SendInvite => _t('Gửi lời mời', 'Send invite', 'Envoyer l’invitation');
  String get s9PhoneError => _t(
        'Số điện thoại quá ngắn. Hãy nhập đầy đủ số di động (ít nhất 9 chữ số).',
        'This number looks too short. Include the full mobile number.',
        'Ce numéro semble trop court. Saisissez le numéro complet.',
      );
  String get s9BadgeJoined => _t('Đã tham gia', 'Joined', 'Inscrit');
  String get s9BadgeInvited => _t('Đã mời', 'Invited', 'Invité');
  String get s9YouThisPhone => _t('Bạn · Điện thoại này', 'You · this phone', 'Vous · ce téléphone');
  String get s9MoveUp => _t('Đưa lên', 'Move up', 'Monter');
  String get s9MoveDown => _t('Đưa xuống', 'Move down', 'Descendre');

  // Medical & Safety tools (retained from existing Fall Guard app)
  String get medicalSuiteTitle => _t('Chăm sóc & Y tế khẩn cấp', 'Elderly Care & Medical Kit', 'Soins & Kit Médical');
  String get firstAidTitle => _t('Hướng dẫn sơ cứu té ngã', 'Fall First Aid Guide', 'Premiers secours chute');
  String get firstAidSub => _t('4 bước chuẩn y khoa khi phát hiện người già ngã', '4 step-by-step clinical instructions', '4 étapes cliniques illustrées');
  String get medicalIdTitle => _t('Thẻ Hồ sơ Y tế Khẩn cấp', 'Emergency Medical ID Card', 'Fiche médicale d’urgence');
  String get medicalIdSub => _t('Nhóm máu, bệnh nền, thuốc & bác sĩ điều trị', 'Blood type, conditions, meds & doctor', 'Groupe sanguin, antécédents, traitements');
  String get steadiTitle => _t('Đánh giá nguy cơ té ngã CDC STEADI', 'CDC STEADI Fall Risk Check', 'Évaluation risque de chute STEADI');
  String get steadiSub => _t('Bộ câu hỏi tầm soát nguy cơ ngã cho người cao tuổi', '12-point clinical fall risk screening', 'Questionnaire clinique en 12 points');
  String get auditReportTitle => _t('Báo cáo kiểm tra y tế tổng hợp', 'Medical Safety Audit Report', 'Rapport de sécurité médicale');
  String get auditReportSub => _t('Tổng hợp chỉ số STEADI, lịch sử sự cố & sức khỏe cảm biến', 'Combined STEADI score, incidents & sensor health', 'Synthèse STEADI, incidents et capteurs');
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
