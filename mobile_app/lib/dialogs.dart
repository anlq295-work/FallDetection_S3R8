part of 'main.dart';

class FirstAidGuideDialog extends StatefulWidget {
  const FirstAidGuideDialog({super.key});

  @override
  State<FirstAidGuideDialog> createState() => _FirstAidGuideDialogState();
}

class _FirstAidGuideDialogState extends State<FirstAidGuideDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _call115() async {
    final uri = Uri.parse("tel:115");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildTipCard(String title, String content, {Color color = Colors.amberAccent, IconData icon = Icons.lightbulb}) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> bodyItems,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  number,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bodyItems,
        ],
      ),
    );
  }

  Widget _bulletText(String boldPrefix, String text, {Color? prefixColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Colors.white60, fontSize: 15)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
                children: [
                  if (boldPrefix.isNotEmpty)
                    TextSpan(
                      text: "$boldPrefix: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: prefixColor ?? Colors.cyanAccent),
                    ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subItemCard(String subTitle, List<Widget> items, {Color color = Colors.cyanAccent}) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subTitle,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: color),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }

  Widget _buildPrecautionsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.cyanAccent, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Trước khi thực hiện sơ cấp cứu, bạn cần đảm bảo một số điều quan trọng để xử lý đúng cách và an toàn:",
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          _buildStepCard(
            number: "1",
            title: "Đánh giá mức độ chấn thương",
            icon: Icons.visibility,
            color: Colors.cyanAccent,
            bodyItems: [
              _bulletText("Quan sát kỹ người bị nạn", "Họ có còn tỉnh táo không?"),
              _bulletText("Kiểm tra nhanh tình trạng cơ thể", "Có vết thương hở, máu chảy hay không."),
            ],
          ),
          _buildStepCard(
            number: "2",
            title: "Đảm bảo an toàn",
            icon: Icons.health_and_safety,
            color: Colors.amberAccent,
            bodyItems: [
              _bulletText("Khu vực an toàn", "Đưa người bị nạn ra khỏi khu vực nguy hiểm (nếu có thể)."),
              _bulletText("Tránh di chuyển", "Tránh di chuyển người bị nạn nếu nghi ngờ chấn thương cột sống.", prefixColor: Colors.orangeAccent),
            ],
          ),
          _buildStepCard(
            number: "3",
            title: "Gọi hỗ trợ y tế nếu cần thiết",
            icon: Icons.emergency,
            color: Colors.redAccent,
            bodyItems: [
              _bulletText("Chấn thương nghiêm trọng", "Nếu nhận thấy chấn thương nghiêm trọng (ví dụ: mất ý thức, gãy xương hở, chảy máu nhiều), hãy gọi ngay 115 hoặc đưa họ đến bệnh viện."),
              _buildTipCard(
                "Mẹo nhỏ khi gọi cấp cứu",
                "Khi gọi cấp cứu 115, hãy cung cấp thông tin chi tiết về tình trạng nạn nhân và vị trí chính xác của bạn để giúp đội ngũ y tế phản ứng nhanh hơn.",
                color: Colors.amberAccent,
                icon: Icons.lightbulb,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicStepsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.cyanAccent, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Khi đã đảm bảo an toàn, hãy thực hiện các bước sơ cấp cứu cơ bản dưới đây:",
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          _buildStepCard(
            number: "1",
            title: "Kiểm tra tình trạng ý thức",
            icon: Icons.psychology,
            color: Colors.purpleAccent,
            bodyItems: [
              _bulletText("Phản xạ", "Gọi to hoặc lay nhẹ người bị nạn để xem họ có phản ứng hay không."),
              _bulletText("Nhịp thở & CPR", "Nếu họ không phản ứng, hãy kiểm tra nhịp thở và chuẩn bị thực hiện hồi sức tim phổi (CPR) nếu cần.", prefixColor: Colors.redAccent),
            ],
          ),
          _buildStepCard(
            number: "2",
            title: "Xử lý vết thương hở (nếu có)",
            icon: Icons.healing,
            color: Colors.tealAccent,
            bodyItems: [
              _bulletText("Rửa vết thương", "Rửa sạch vết thương bằng nước sạch hoặc dung dịch sát khuẩn."),
              _bulletText("Băng bó vô trùng", "Dùng băng gạc vô trùng băng lại để ngăn ngừa nhiễm trùng."),
            ],
          ),
          _buildStepCard(
            number: "3",
            title: "Xử lý chấn thương phần mềm",
            icon: Icons.ac_unit,
            color: Colors.lightBlueAccent,
            bodyItems: [
              _bulletText("Chườm lạnh", "Dùng túi đá hoặc khăn lạnh chườm vào vùng bị sưng trong 15-20 phút."),
              _bulletText("Cảnh báo quan trọng", "Không massage hay ấn mạnh vào vùng tổn thương, điều này có thể làm tình trạng nặng thêm.", prefixColor: Colors.redAccent),
            ],
          ),
          _buildStepCard(
            number: "4",
            title: "Hỗ trợ người bị nạn di chuyển",
            icon: Icons.accessible_forward,
            color: Colors.orangeAccent,
            bodyItems: [
              _bulletText("Hỗ trợ nhẹ nhàng", "Nếu cần di chuyển, hãy giúp đỡ nhẹ nhàng, tránh gây thêm tổn thương."),
              _bulletText("Nghi ngờ gãy xương", "Trường hợp nghi ngờ gãy xương, hãy cố định phần bị chấn thương trước khi di chuyển.", prefixColor: Colors.amberAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificCasesTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.category, color: Colors.cyanAccent, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Mỗi trường hợp té ngã sẽ cần cách xử lý khác nhau dựa trên mức độ nghiêm trọng của chấn thương:",
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          _buildStepCard(
            number: "1",
            title: "Cách xử lý té ngã gây chấn thương nhẹ",
            icon: Icons.healing_outlined,
            color: Colors.tealAccent,
            bodyItems: [
              _subItemCard(
                "Trầy xước ngoài da",
                [
                  _bulletText("Làm sạch vết thương", "Rửa bằng nước sạch hoặc dung dịch sát khuẩn."),
                  _bulletText("Băng bó", "Sử dụng băng gạc vô trùng để che phủ vết thương, giúp ngăn ngừa nhiễm trùng."),
                  _bulletText("Vệ sinh định kỳ", "Thay băng hàng ngày hoặc khi băng bị ướt/bẩn."),
                ],
                color: Colors.tealAccent,
              ),
              _subItemCard(
                "Sưng bầm tím",
                [
                  _bulletText("Chườm lạnh", "Dùng túi đá hoặc khăn lạnh chườm lên vùng bầm trong 15-20 phút để giảm sưng."),
                  _bulletText("Nâng cao vùng thương", "Nếu có thể, giữ vùng tổn thương cao hơn tim để giảm sưng."),
                  _bulletText("Lưu ý y tế", "Nếu tình trạng đau hoặc bầm tím kéo dài hơn 48 giờ mà không giảm, hãy tham khảo ý kiến bác sĩ.", prefixColor: Colors.amberAccent),
                ],
                color: Colors.cyanAccent,
              ),
            ],
          ),
          _buildStepCard(
            number: "2",
            title: "Cách xử lý té ngã gây chấn thương nặng",
            icon: Icons.warning_amber_rounded,
            color: Colors.redAccent,
            bodyItems: [
              _subItemCard(
                "Gãy xương",
                [
                  _bulletText("Cố định xương gãy", "Sử dụng nẹp hoặc vật cứng (ví dụ: thanh gỗ hoặc bìa cứng) để cố định vùng bị gãy, tránh di lệch xương."),
                  _bulletText("Không tự ý nắn chỉnh", "Tuyệt đối không cố gắng nắn xương về vị trí ban đầu vì có thể làm tổn thương thêm mạch máu, dây thần kinh hoặc mô xung quanh.", prefixColor: Colors.redAccent),
                  _bulletText("Đến bệnh viện ngay", "Nhanh chóng đưa nạn nhân đến cơ sở y tế gần nhất hoặc gọi cấp cứu 115.", prefixColor: Colors.amberAccent),
                ],
                color: Colors.orangeAccent,
              ),
              _subItemCard(
                "Chấn thương đầu",
                [
                  _bulletText("Theo dõi dấu hiệu", "Chú ý các biểu hiện nguy hiểm như buồn nôn, chóng mặt dữ dội, mất trí nhớ tạm thời, co giật hoặc chảy máu từ tai, mũi.", prefixColor: Colors.redAccent),
                  _bulletText("Giữ đầu cố định", "Hạn chế tối đa việc di chuyển đầu hoặc cổ của người bị nạn. Nếu cần nằm, hãy giữ đầu ngang bằng với thân mình."),
                  _bulletText("Xử lý nôn ói (Tư thế nghiêng)", "Nếu người bị nạn nôn, hãy nhẹ nhàng nghiêng cả người họ sang một bên (tư thế nằm nghiêng an toàn) để tránh chất nôn tràn vào đường thở gây ngạt thở.", prefixColor: Colors.amberAccent),
                  _bulletText("Đến bệnh viện cấp cứu", "Chấn thương đầu có thể tiềm ẩn xuất huyết não nguy hiểm, cần đưa người bị nạn đến bệnh viện ngay cả khi họ cảm thấy bình thường sau cú ngã.", prefixColor: Colors.redAccent),
                ],
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 580, maxHeight: screenHeight * 0.9),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.medical_services, color: Colors.redAccent, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cẩm nang Sơ cứu Người bị Té ngã",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.5, color: Colors.white),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Hướng dẫn xử lý chấn thương và sơ cấp cứu an toàn",
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // TabBar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Colors.redAccent,
                  labelColor: Colors.redAccent,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  tabs: const [
                    Tab(text: "1. Lưu ý trước sơ cứu"),
                    Tab(text: "2. Các bước cơ bản"),
                    Tab(text: "3. Theo trường hợp cụ thể"),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPrecautionsTab(),
                    _buildBasicStepsTab(),
                    _buildSpecificCasesTab(),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.phone_in_talk, size: 20),
                      label: const Text("Gọi Cấp Cứu 115", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: _call115,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      side: BorderSide(color: Colors.grey.shade700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Đóng", style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// 1. Hình vẽ minh họa Bước 1: Cấm kéo đứng dậy ngay
class DoNotPullIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // Mặt sàn
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // Người nằm trên sàn
    final double bodyX = w * 0.40;
    final Paint bodyPaint = Paint()
      ..color = Colors.blueGrey.shade300
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Đầu gối trên sàn
    canvas.drawCircle(Offset(bodyX - 50, floorY - 10), 9, bodyPaint);
    // Thân
    canvas.drawLine(Offset(bodyX - 40, floorY - 8), Offset(bodyX + 25, floorY - 8), bodyPaint);
    // Chân
    canvas.drawLine(Offset(bodyX + 25, floorY - 8), Offset(bodyX + 80, floorY - 8), bodyPaint);

    // Vòng cảnh báo đỏ ở Cổ và Hông
    final Paint alertRing = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset(bodyX - 35, floorY - 8), 16, alertRing); // Cổ
    canvas.drawCircle(Offset(bodyX + 25, floorY - 8), 18, alertRing); // Hông

    // Bàn tay kéo giật từ trên xuống (Dashed vector)
    final Paint pullArrow = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(bodyX - 10, floorY - 60), Offset(bodyX - 10, floorY - 18), pullArrow);

    // Biển cấm kéo đứng dậy
    final Paint signPaint = Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = 2.5;
    canvas.drawCircle(Offset(w * 0.78, h * 0.45), 26, signPaint);
    canvas.drawLine(Offset(w * 0.78 - 18, h * 0.45 - 18), Offset(w * 0.78 + 18, h * 0.45 + 18), signPaint);

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "CẤM KÉO DẬY!",
      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10),
    );
    tp.layout();
    tp.paint(canvas, Offset(w * 0.78 - tp.width / 2, h * 0.45 + 32));

    // Nhãn vùng nguy hiểm
    final TextPainter tpLabel = TextPainter(textDirection: TextDirection.ltr);
    tpLabel.text = const TextSpan(
      text: "Nguy cơ gãy cổ xương đùi & tổn thương tủy sống",
      style: TextStyle(color: Colors.white60, fontSize: 9.5),
    );
    tpLabel.layout();
    tpLabel.paint(canvas, const Offset(15, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Hình vẽ minh họa Bước 2: Kiểm tra tri giác & Gọi 115
class VitalsCheckIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // Mặt sàn
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // Nạn nhân nằm
    final double vicX = w * 0.32;
    final Paint vicPaint = Paint()..color = Colors.blueGrey.shade400..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(vicX - 45, floorY - 9), 8, vicPaint);
    canvas.drawLine(Offset(vicX - 35, floorY - 7), Offset(vicX + 35, floorY - 7), vicPaint);
    canvas.drawLine(Offset(vicX + 35, floorY - 7), Offset(vicX + 85, floorY - 7), vicPaint);

    // Người sơ cứu quỳ một bên kiểm tra
    final double rescX = vicX - 5;
    final Paint rescPaint = Paint()..color = Colors.tealAccent..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(rescX - 10, floorY - 55), 8, rescPaint); // Đầu người sơ cứu
    canvas.drawLine(Offset(rescX - 10, floorY - 47), Offset(rescX, floorY - 25), rescPaint); // Thân
    canvas.drawLine(Offset(rescX, floorY - 25), Offset(rescX - 15, floorY), rescPaint); // Chân quỳ
    canvas.drawLine(Offset(rescX - 10, floorY - 40), Offset(vicX, floorY - 10), rescPaint); // Tay bắt mạch / kiểm tra

    // Hộp thoại hỏi thăm
    final Paint bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final RRect bubbleRRect = RRect.fromRectAndRadius(Rect.fromLTWH(vicX - 60, 10, 160, 26), const Radius.circular(8));
    canvas.drawRRect(bubbleRRect, bubblePaint);

    final TextPainter tpMsg = TextPainter(textDirection: TextDirection.ltr);
    tpMsg.text = const TextSpan(
      text: "Bác tỉnh không? Có đau ở đâu không?",
      style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
    );
    tpMsg.layout();
    tpMsg.paint(canvas, Offset(vicX - 55, 16));

    // Huy hiệu cấp cứu 115
    final Paint sosBox = Paint()..color = Colors.red.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    final RRect sosRRect = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.72, 25, 95, 60), const Radius.circular(10));
    canvas.drawRRect(sosRRect, sosBox);
    canvas.drawRRect(sosRRect, Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final TextPainter tp115 = TextPainter(textDirection: TextDirection.ltr);
    tp115.text = const TextSpan(
      text: "CẤP CỨU 115\nKhi bất tỉnh hoặc\nnghi gãy xương",
      style: TextStyle(color: Colors.redAccent, fontSize: 9.5, fontWeight: FontWeight.bold, height: 1.3),
    );
    tp115.layout();
    tp115.paint(canvas, Offset(w * 0.72 + 8, 32));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Hình vẽ minh họa Bước 3: Tư thế hồi sức nằm nghiêng
class RecoveryPositionIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // Mặt sàn
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // Người nằm nghiêng an toàn
    final double cx = w * 0.38;
    final Paint p = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Đầu kê lên mu bàn tay
    canvas.drawCircle(Offset(cx - 55, floorY - 18), 9, p);
    // Tay đỡ đầu
    canvas.drawLine(Offset(cx - 35, floorY - 14), Offset(cx - 55, floorY - 10), p);
    // Thân nằm nghiêng
    canvas.drawLine(Offset(cx - 45, floorY - 14), Offset(cx + 25, floorY - 14), p);
    // Chân dưới duỗi thẳng
    canvas.drawLine(Offset(cx + 25, floorY - 14), Offset(cx + 85, floorY - 14), p..color = Colors.teal.shade700);
    // Chân trên co vuông góc 90 độ chạm sàn để giữ thăng bằng
    final Paint pLeg = Paint()..color = Colors.tealAccent..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 25, floorY - 14), Offset(cx + 35, floorY - 3), pLeg);
    canvas.drawLine(Offset(cx + 35, floorY - 3), Offset(cx + 65, floorY - 3), pLeg);

    // Mũi tên luồng thở thông thoáng
    final Paint airwayPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 2.0..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx - 68, floorY - 18), radius: 12), 0.5, 2.0, false, airwayPaint);

    // Nhãn chú thích
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "Tư thế nằm nghiêng an toàn (IFRC/AHA):\n• Cằm ngửa nhẹ -> Đường thở mở rộng\n• Chân co 90° giữ thăng bằng vững\n• Chống sặc dịch nôn/nước bọt vào phổi",
      style: TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.4),
    );
    tp.layout();
    tp.paint(canvas, Offset(w * 0.48, 15));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. Hình vẽ minh họa Bước 4: Quy tắc dùng ghế đứng dậy (NHS UK)
class ChairMethodIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 22;

    // Mặt sàn
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // Ghế tựa ở bên phải
    final double chairX = w * 0.82;
    final Paint chairPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 2.5..style = PaintingStyle.stroke;
    // Chân ghế
    canvas.drawLine(Offset(chairX, floorY), Offset(chairX, floorY - 45), chairPaint);
    canvas.drawLine(Offset(chairX + 30, floorY), Offset(chairX + 30, floorY - 45), chairPaint);
    // Mặt ghế
    canvas.drawLine(Offset(chairX - 5, floorY - 45), Offset(chairX + 35, floorY - 45), chairPaint);
    // Lưng tựa ghế
    canvas.drawLine(Offset(chairX + 30, floorY - 45), Offset(chairX + 30, floorY - 80), chairPaint);

    // 3 giai đoạn tiến triển
    final Paint stepPaint = Paint()..color = Colors.white70..strokeWidth = 2.5..strokeCap = StrokeCap.round;

    // A. Nằm nghiêng
    canvas.drawCircle(Offset(35, floorY - 8), 6, stepPaint);
    canvas.drawLine(Offset(41, floorY - 6), Offset(65, floorY - 6), stepPaint);

    // Mũi tên sang B
    canvas.drawLine(Offset(75, floorY - 15), Offset(95, floorY - 15), floorPaint);

    // B. Quỳ 4 điểm (bò)
    canvas.drawCircle(Offset(125, floorY - 24), 6, stepPaint);
    canvas.drawLine(Offset(125, floorY - 18), Offset(145, floorY - 18), stepPaint);
    canvas.drawLine(Offset(125, floorY - 18), Offset(125, floorY), stepPaint);
    canvas.drawLine(Offset(145, floorY - 18), Offset(145, floorY), stepPaint);

    // Mũi tên sang C
    canvas.drawLine(Offset(160, floorY - 25), Offset(180, floorY - 25), floorPaint);

    // C. Vịn 2 tay lên ghế
    canvas.drawCircle(Offset(225, floorY - 42), 6, stepPaint);
    canvas.drawLine(Offset(225, floorY - 36), Offset(225, floorY - 15), stepPaint);
    canvas.drawLine(Offset(225, floorY - 15), Offset(215, floorY), stepPaint);
    canvas.drawLine(Offset(225, floorY - 15), Offset(235, floorY), stepPaint);
    canvas.drawLine(Offset(225, floorY - 30), Offset(chairX - 5, floorY - 45), Paint()..color = Colors.amberAccent..strokeWidth = 2.5); // Tay vịn ghế

    // Nhãn 4 bước
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "1. Nằm nghiêng ➔ 2. Quỳ 4 điểm ➔ 3. Vịn ghế vững ➔ 4. ĐÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©y chân ngồi lên ghế",
      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10),
    );
    tp.layout();
    tp.paint(canvas, const Offset(15, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// =========================================================================
// TÍNH NĂNG 2: HỒ SƠ Y TẾ KHẨN CẤP NGƯỜI CAO TUỔI (MEDICAL EMERGENCY PROFILE)
// =========================================================================
class ElderlyMedicalProfile {
  String fullName;
  int birthYear;
  String gender;
  String bloodType;
  List<String> chronicConditions;
  List<String> highRiskMedications;
  String allergies;
  String emergencyContact1Name;
  String emergencyContact1Phone;
  String emergencyContact2Name;
  String emergencyContact2Phone;
  String attendingDoctorName;
  String attendingDoctorPhone;
  String hospital;
  String notes;

  ElderlyMedicalProfile({
    this.fullName = "Nguyễn Văn An",
    this.birthYear = 1948,
    this.gender = "Nam",
    this.bloodType = "O+",
    this.chronicConditions = const ["Tăng huyết áp", "Loãng xương", "Bệnh mạch vành"],
    this.highRiskMedications = const ["Thuốc chống đông máu (Aspirin / Warfarin)", "Thuốc hạ áp Amlodipine"],
    this.allergies = "Chưa ghi nhận",
    this.emergencyContact1Name = "Con trai (Nguyễn Tuấn)",
    this.emergencyContact1Phone = "0987654321",
    this.emergencyContact2Name = "Con gái (Nguyễn Mai)",
    this.emergencyContact2Phone = "0912345678",
    this.attendingDoctorName = "BS. CKII Lê Hoàng",
    this.attendingDoctorPhone = "0903115115",
    this.hospital = "BV Lão Khoa TW / BV Đa Khoa Tỉnh",
    this.notes = "Người bệnh có tiền sử thay khớp háng nhân tạo năm 2022. Chìa khóa nhà dự phòng gửi tại căn hộ 402.",
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'birthYear': birthYear,
    'gender': gender,
    'bloodType': bloodType,
    'chronicConditions': chronicConditions,
    'highRiskMedications': highRiskMedications,
    'allergies': allergies,
    'emergencyContact1Name': emergencyContact1Name,
    'emergencyContact1Phone': emergencyContact1Phone,
    'emergencyContact2Name': emergencyContact2Name,
    'emergencyContact2Phone': emergencyContact2Phone,
    'attendingDoctorName': attendingDoctorName,
    'attendingDoctorPhone': attendingDoctorPhone,
    'hospital': hospital,
    'notes': notes,
  };

  factory ElderlyMedicalProfile.fromJson(Map<String, dynamic> json) {
    return ElderlyMedicalProfile(
      fullName: json['fullName'] ?? "Nguyễn Văn An",
      birthYear: json['birthYear'] ?? 1948,
      gender: json['gender'] ?? "Nam",
      bloodType: json['bloodType'] ?? "O+",
      chronicConditions: json['chronicConditions'] != null
          ? List<String>.from(json['chronicConditions'])
          : ["Tăng huyết áp", "Loãng xương"],
      highRiskMedications: json['highRiskMedications'] != null
          ? List<String>.from(json['highRiskMedications'])
          : ["Thuốc chống đông máu (Aspirin / Warfarin)"],
      allergies: json['allergies'] ?? "Chưa ghi nhận",
      emergencyContact1Name: json['emergencyContact1Name'] ?? "Con trai (Nguyễn Tuấn)",
      emergencyContact1Phone: json['emergencyContact1Phone'] ?? "0987654321",
      emergencyContact2Name: json['emergencyContact2Name'] ?? "Con gái (Nguyễn Mai)",
      emergencyContact2Phone: json['emergencyContact2Phone'] ?? "0912345678",
      attendingDoctorName: json['attendingDoctorName'] ?? "BS. CKII Lê Hoàng",
      attendingDoctorPhone: json['attendingDoctorPhone'] ?? "0903115115",
      hospital: json['hospital'] ?? "BV Lão Khoa TW",
      notes: json['notes'] ?? "",
    );
  }

  static Future<ElderlyMedicalProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('elderly_medical_profile');
    if (raw != null) {
      try {
        return ElderlyMedicalProfile.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return ElderlyMedicalProfile();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elderly_medical_profile', jsonEncode(toJson()));
  }

  bool get isTakingAnticoagulants => highRiskMedications.any((m) =>
      m.toLowerCase().contains("chống đông") ||
      m.toLowerCase().contains("aspirin") ||
      m.toLowerCase().contains("warfarin") ||
      m.toLowerCase().contains("clopidogrel") ||
      m.toLowerCase().contains("xarelto") ||
      m.toLowerCase().contains("eliquis"));
}

// =========================================================================
// THẺ Y TẾ CẤP CỨU KHẨN CẤP (EMERGENCY MEDICAL ID CARD DIALOG)
// =========================================================================
class EmergencyMedicalIdCardDialog extends StatelessWidget {
  final ElderlyMedicalProfile profile;
  final VoidCallback onEdit;

  const EmergencyMedicalIdCardDialog({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  int get age => DateTime.now().year - profile.birthYear;

  void _callNumber(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isNotEmpty) {
      final uri = Uri.parse("tel:$clean");
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  void _copySummary(BuildContext context) {
    final text = """
[THẺ Y TẾ CẤP CỨU KHẨN CẤP - FALLGUARD]
Họ tên: ${profile.fullName} ($age tuổi - Sinh năm ${profile.birthYear} - ${profile.gender})
Nhóm máu: ${profile.bloodType}
CẢNH BÁO THUỐC CHỐNG ĐÔNG: ${profile.isTakingAnticoagulants ? 'CÓ (NGUY CƠ XUẤT HUYẾT NỘI SỌ CAO)' : 'Không'}
Bệnh lý nền: ${profile.chronicConditions.join(', ')}
Thuốc đang dùng: ${profile.highRiskMedications.join(', ')}
Dị ứng: ${profile.allergies}
Bác sĩ điều trị: ${profile.attendingDoctorName} (${profile.attendingDoctorPhone})
Bệnh viện chỉ định: ${profile.hospital}
Người thân 1: ${profile.emergencyContact1Name} (${profile.emergencyContact1Phone})
Người thân 2: ${profile.emergencyContact2Name} (${profile.emergencyContact2Phone})
Ghi chú: ${profile.notes}
""";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã sao chép tóm tắt y tế vào bộ nhớ tạm!"), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tiêu đề & Biểu tượng Cấp Cứu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("THẺ Y TẾ CẤP CỨU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                        Text("Dành cho Nhân viên Y tế 115 & Cứu hộ", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                    tooltip: "Chỉnh sửa hồ sơ",
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                  ),
                ],
              ),
              const Divider(height: 24),

              // Bảng tóm tắt bệnh nhân & nhóm máu
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                          const SizedBox(height: 4),
                          Text("$age tuổi (${profile.birthYear}) • Giới tính: ${profile.gender}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Text("NHÓM MÁU", style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold)),
                          Text(profile.bloodType, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // CẢNH BÁO ĐẶC BIỆT NẾU DÙNG THUỐC CHỐNG ĐÔNG MÁU
              if (profile.isTakingAnticoagulants)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amberAccent, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amberAccent, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "CẢNH BÁO LÂM SÀNG: Người bệnh đang dùng THUỐC CHỐNG ĐÔNG MÁU (Aspirin/Warfarin...). Nguy cơ xuất huyết nội sọ cao khi chấn thương té ngã!",
                          style: TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Bệnh lý nền
              const Text("Tiền sử bệnh lý nền:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.chronicConditions.map((c) => Chip(
                  label: Text(c, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.blueGrey.withValues(alpha: 0.25),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 12),

              // Thuốc đang sử dụng
              const Text("Thuốc đặc biệt cần lưu ý:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.highRiskMedications.map((m) => Chip(
                  label: Text(m, style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  side: const BorderSide(color: Colors.redAccent, width: 0.8),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 12),

              // Dị ứng & Bệnh viện
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBlock("Dị ứng:", profile.allergies, Icons.no_food),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoBlock("BV chỉ định:", profile.hospital, Icons.local_hospital),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Danh bạ cấp cứu gọi nhanh 1 chạm
              const Text("Liên hệ khẩn cấp 1 chạm:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _callNumber("115"),
                      icon: const Icon(Icons.phone_in_talk, size: 16),
                      label: const Text("Cấp cứu 115", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _callNumber(profile.emergencyContact1Phone),
                      icon: const Icon(Icons.call, size: 16),
                      label: Text(profile.emergencyContact1Name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (profile.emergencyContact2Phone.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _callNumber(profile.emergencyContact2Phone),
                  icon: const Icon(Icons.call, size: 16),
                  label: Text("Người thân 2: ${profile.emergencyContact2Name} (${profile.emergencyContact2Phone})", style: const TextStyle(fontSize: 12)),
                ),
              const SizedBox(height: 12),

              // Nút sao chép & Đóng
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copySummary(context),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text("Sao chép tóm tắt"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Đóng"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// =========================================================================
// MÀN HÌNH CHỈNH SỬA HỒ SƠ Y TẾ NGƯỜI CAO TUỔI (MEDICAL PROFILE EDIT DIALOG)
// =========================================================================
class MedicalProfileEditDialog extends StatefulWidget {
  final ElderlyMedicalProfile profile;
  final Function(ElderlyMedicalProfile) onSaved;

  const MedicalProfileEditDialog({super.key, required this.profile, required this.onSaved});

  @override
  State<MedicalProfileEditDialog> createState() => _MedicalProfileEditDialogState();
}

class _MedicalProfileEditDialogState extends State<MedicalProfileEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _allergiesCtrl;
  late TextEditingController _c1NameCtrl;
  late TextEditingController _c1PhoneCtrl;
  late TextEditingController _c2NameCtrl;
  late TextEditingController _c2PhoneCtrl;
  late TextEditingController _doctorNameCtrl;
  late TextEditingController _doctorPhoneCtrl;
  late TextEditingController _hospitalCtrl;
  late TextEditingController _notesCtrl;

  late String _gender;
  late String _bloodType;
  late List<String> _selectedConditions;
  late List<String> _selectedMeds;

  final List<String> _availableConditions = [
    "Tăng huyết áp",
    "Đái tháo đường Type 2",
    "Bệnh mạch vành / Tim mạch",
    "Loãng xương nặng",
    "Tiền sử đột quỵ / Tai biến",
    "Parkinson",
    "Rối loạn tiền đình",
    "Suy giảm trí nhớ / Sa sút trí tuệ",
  ];

  final List<String> _availableMeds = [
    "Thuốc chống đông máu (Aspirin / Warfarin)",
    "Thuốc kháng tiểu cầu (Clopidogrel / Plavix)",
    "Thuốc chống đông thế hệ mới (Xarelto / Eliquis)",
    "Thuốc hạ áp (Amlodipine / Losartan...)",
    "Insulin / Thuốc tiểu đường",
    "Thuốc an thần / Thuốc ngủ",
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.fullName);
    _yearCtrl = TextEditingController(text: p.birthYear.toString());
    _allergiesCtrl = TextEditingController(text: p.allergies);
    _c1NameCtrl = TextEditingController(text: p.emergencyContact1Name);
    _c1PhoneCtrl = TextEditingController(text: p.emergencyContact1Phone);
    _c2NameCtrl = TextEditingController(text: p.emergencyContact2Name);
    _c2PhoneCtrl = TextEditingController(text: p.emergencyContact2Phone);
    _doctorNameCtrl = TextEditingController(text: p.attendingDoctorName);
    _doctorPhoneCtrl = TextEditingController(text: p.attendingDoctorPhone);
    _hospitalCtrl = TextEditingController(text: p.hospital);
    _notesCtrl = TextEditingController(text: p.notes);
    _gender = p.gender;
    _bloodType = p.bloodType;
    _selectedConditions = List<String>.from(p.chronicConditions);
    _selectedMeds = List<String>.from(p.highRiskMedications);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yearCtrl.dispose();
    _allergiesCtrl.dispose();
    _c1NameCtrl.dispose();
    _c1PhoneCtrl.dispose();
    _c2NameCtrl.dispose();
    _c2PhoneCtrl.dispose();
    _doctorNameCtrl.dispose();
    _doctorPhoneCtrl.dispose();
    _hospitalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = ElderlyMedicalProfile(
      fullName: _nameCtrl.text.trim().isEmpty ? "Nguyễn Văn An" : _nameCtrl.text.trim(),
      birthYear: int.tryParse(_yearCtrl.text.trim()) ?? 1948,
      gender: _gender,
      bloodType: _bloodType,
      chronicConditions: _selectedConditions,
      highRiskMedications: _selectedMeds,
      allergies: _allergiesCtrl.text.trim().isEmpty ? "Chưa ghi nhận" : _allergiesCtrl.text.trim(),
      emergencyContact1Name: _c1NameCtrl.text.trim(),
      emergencyContact1Phone: _c1PhoneCtrl.text.trim(),
      emergencyContact2Name: _c2NameCtrl.text.trim(),
      emergencyContact2Phone: _c2PhoneCtrl.text.trim(),
      attendingDoctorName: _doctorNameCtrl.text.trim(),
      attendingDoctorPhone: _doctorPhoneCtrl.text.trim(),
      hospital: _hospitalCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    updated.save();
    widget.onSaved(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Hồ sơ y tế khẩn cấp đã được lưu thành công!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.badge, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("Cập nhật hồ sơ y tế khẩn cấp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  const Text("1. Thông tin bệnh nhân", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: "Họ và tên người cao tuổi", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Năm sinh (VD: 1948)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.cake)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _bloodType,
                          decoration: const InputDecoration(labelText: "Nhóm máu", border: OutlineInputBorder(), prefixIcon: Icon(Icons.bloodtype)),
                          items: ["O+", "A+", "B+", "AB+", "O-", "A-", "B-", "AB-", "Chưa rõ"].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (val) => setState(() => _bloodType = val ?? "O+"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text("2. Tiền sử bệnh lý nền (Chọn các bệnh áp dụng)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 6),
                  ..._availableConditions.map((cond) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(cond, style: const TextStyle(fontSize: 13)),
                    value: _selectedConditions.contains(cond),
                    onChanged: (chk) {
                      setState(() {
                        if (chk == true) {
                          _selectedConditions.add(cond);
                        } else {
                          _selectedConditions.remove(cond);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 16),

                  const Text("3. Thuốc đặc biệt (Cực kỳ quan trọng khi cấp cứu)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 6),
                  ..._availableMeds.map((med) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(med, style: TextStyle(fontSize: 13, color: med.contains("chống đông") ? Colors.redAccent : null)),
                    value: _selectedMeds.contains(med),
                    onChanged: (chk) {
                      setState(() {
                        if (chk == true) {
                          _selectedMeds.add(med);
                        } else {
                          _selectedMeds.remove(med);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 16),

                  const Text("4. Danh bạ khẩn cấp & Bác sĩ điều trị", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _c1NameCtrl, decoration: const InputDecoration(labelText: "Người thân 1 (Tên/Quan hệ)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _c1PhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SĐT Người thân 1", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _c2NameCtrl, decoration: const InputDecoration(labelText: "Người thân 2 (Tên/Quan hệ)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _c2PhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SĐT Người thân 2", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _doctorNameCtrl, decoration: const InputDecoration(labelText: "Bác sĩ riêng", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _doctorPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SĐT Bác sĩ", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _hospitalCtrl, decoration: const InputDecoration(labelText: "Bệnh viện ưu tiên chỉ định chuyển viện", border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_hospital))),
                  const SizedBox(height: 10),
                  TextField(controller: _allergiesCtrl, decoration: const InputDecoration(labelText: "Dị ứng thuốc / thức ăn", border: OutlineInputBorder(), prefixIcon: Icon(Icons.warning))),
                  const SizedBox(height: 10),
                  TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Ghi chú cấp cứu khác (Vị trí chìa khóa dự phòng, tiền sử mổ...)", border: OutlineInputBorder())),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text("Lưu hồ sơ y tế", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÍNH NĂNG 7: ĐÁNH GIÁ NGUY CƠ TÉ NGÃ THEO CHUẨN CDC STEADI (12 CÂU HỎI)
// =========================================================================
class CdcSteadiAssessmentDialog extends StatefulWidget {
  final Function(int score, String riskLevel) onCompleted;

  const CdcSteadiAssessmentDialog({super.key, required this.onCompleted});

  @override
  State<CdcSteadiAssessmentDialog> createState() => _CdcSteadiAssessmentDialogState();
}

class _CdcSteadiAssessmentDialogState extends State<CdcSteadiAssessmentDialog> {
  // 12 câu hỏi chuẩn CDC STEADI (Stay Independent Brochure)
  final List<Map<String, dynamic>> _questions = [
    {
      "text": "1. Tôi từng bị ngã trong vòng 1 năm qua.",
      "pts": 2,
      "why": "Người từng ngã có nguy cơ tái ngã cao gấp 3 lần.",
      "ans": false,
    },
    {
      "text": "2. Tôi cần dùng gậy chống hoặc khung tập đi, hoặc bác sĩ khuyên tôi nên dùng.",
      "pts": 2,
      "why": "Dấu hiệu suy giảm sức cơ chân và thăng bằng dáng đi.",
      "ans": false,
    },
    {
      "text": "3. Đôi khi tôi cảm thấy loạng choạng hoặc mất thăng bằng khi đi lại.",
      "pts": 1,
      "why": "Rối loạn chức năng tiền đình hoặc yếu cơ chi dưới.",
      "ans": false,
    },
    {
      "text": "4. Tôi hay phải vịn vào đồ đạc, tường khi đi lại trong nhà.",
      "pts": 1,
      "why": "Biểu hiện thiếu tự tin vào khả năng giữ thăng bằng tự thân.",
      "ans": false,
    },
    {
      "text": "5. Tôi thường lo lắng hoặc sợ hãi mình sẽ bị ngã.",
      "pts": 1,
      "why": "Hội chứng sợ ngã (Fear of Falling) dẫn đến hạn chế vận động và teo cơ.",
      "ans": false,
    },
    {
      "text": "6. Tôi cần dùng tay đẩy mạnh vào đùi hoặc ghế mới đứng dậy được.",
      "pts": 1,
      "why": "Suy giảm sức mạnh cơ tứ đầu đùi (quadriceps weakness).",
      "ans": false,
    },
    {
      "text": "7. Tôi cảm thấy khó khăn khi bước lên vỉa hè hoặc bậc thềm cao.",
      "pts": 1,
      "why": "Hạn chế linh hoạt khớp cổ chân và khả năng nâng chân.",
      "ans": false,
    },
    {
      "text": "8. Tôi thường phải vội vã đi gấp vào nhà vệ sinh.",
      "pts": 1,
      "why": "Hội chứng tiểu gấp làm tăng nguy cơ vấp ngã ban đêm.",
      "ans": false,
    },
    {
      "text": "9. Tôi bị tê bì hoặc mất cảm giác ở lòng bàn chân.",
      "pts": 1,
      "why": "Mất cảm thụ bản thể (neuropathy) hay gặp ở người đái tháo đường.",
      "ans": false,
    },
    {
      "text": "10. Tôi đang uống thuốc làm tôi cảm thấy choáng váng hoặc buồn ngủ.",
      "pts": 1,
      "why": "Tác dụng phụ của thuốc hạ huyết áp, an thần hoặc kháng histamine.",
      "ans": false,
    },
    {
      "text": "11. Tôi đang uống thuốc điều trị rối loạn tâm trạng hoặc thuốc hỗ trợ giấc ngủ.",
      "pts": 1,
      "why": "Thuốc ngủ làm giảm phản xạ thăng bằng khi thức dậy giữa đêm.",
      "ans": false,
    },
    {
      "text": "12. Gần đây tôi thường xuyên cảm thấy buồn bã, chán nản hoặc suy giảm tinh thần.",
      "pts": 1,
      "why": "Trầm cảm tuổi già liên quan mật thiết đến suy giảm phối hợp vận động.",
      "ans": false,
    },
  ];

  int get currentScore {
    int s = 0;
    for (var q in _questions) {
      if (q['ans'] == true) s += (q['pts'] as int);
    }
    return s;
  }

  String get riskLevel => currentScore >= 4 ? "NGUY CƠ CAO (High Risk)" : "NGUY CƠ THẤP / VỪA (Low/Mod Risk)";

  void _finish() async {
    final score = currentScore;
    final level = riskLevel;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cdc_steadi_last_score', score);
    await prefs.setString('cdc_steadi_last_date', DateTime.now().toIso8601String());

    // Lưu vào danh sách lịch sử đánh giá
    final List<String> history = prefs.getStringList('cdc_steadi_history') ?? [];
    history.insert(0, jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'score': score,
      'risk': level,
    }));
    await prefs.setStringList('cdc_steadi_history', history);

    widget.onCompleted(score, level);
    if (!mounted) return;
    Navigator.pop(context);

    // Mở hộp thoại thông báo kết quả & lời khuyên y tế
    _showResultDialog(score, level);
  }

  void _showResultDialog(int score, String level) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowAlignment: OverflowBarAlignment.end,
        title: Row(
          children: [
            Icon(score >= 4 ? Icons.warning : Icons.check_circle, color: score >= 4 ? Colors.redAccent : Colors.green),
            const SizedBox(width: 8),
            const Text("Kết quả đánh giá CDC", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (score >= 4 ? Colors.red : Colors.green).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: score >= 4 ? Colors.redAccent : Colors.green),
              ),
              child: Row(
                children: [
                  Text("$score / 14 điểm", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: score >= 4 ? Colors.redAccent : Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(level, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text("Khuyến nghị y tế lâm sàng theo CDC STEADI:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            if (score >= 4) ...[
              const Text("• Cần đo huyết áp tư thế (ngồi và đứng sau 1-3 phút) để tầm soát tụt huyết áp tư thế.", style: TextStyle(fontSize: 12)),
              const Text("• Đề nghị bác sĩ điều trị rà soát đơn thuốc, đặc biệt thuốc an thần và hạ áp.", style: TextStyle(fontSize: 12)),
              const Text("• Lắp đặt thanh vịn tay trong nhà tắm và thảm chống trượt ngay lập tức.", style: TextStyle(fontSize: 12)),
              const Text("• Tập vật lý trị liệu phục hồi chức năng thăng bằng (bài tập Otago / Thái Cực Quyền).", style: TextStyle(fontSize: 12)),
            ] else ...[
              const Text("• Duy trì thói quen tập luyện thể lực hàng ngày (đi bộ, Thái Cực Quyền 30 phút/ngày).", style: TextStyle(fontSize: 12)),
              const Text("• Bổ sung đủ Canxi và Vitamin D theo hướng dẫn của bác sĩ.", style: TextStyle(fontSize: 12)),
              const Text("• Đánh giá lại nguy cơ định kỳ 6 tháng một lần.", style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tôi đã hiểu")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.quiz, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Đánh giá nguy cơ ngã CDC STEADI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Chuẩn y khoa Trung tâm Kiểm soát Bệnh tật Hoa Kỳ (CDC)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),

            // Điểm số trực tiếp
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (currentScore >= 4 ? Colors.red : Colors.green).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: currentScore >= 4 ? Colors.redAccent : Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Điểm số hiện tại: $currentScore / 14 điểm", style: TextStyle(fontWeight: FontWeight.bold, color: currentScore >= 4 ? Colors.redAccent : Colors.green)),
                  Text(currentScore >= 4 ? "Nguy cơ cao (>= 4)" : "Nguy cơ thấp (< 4)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (ctx, idx) {
                  final q = _questions[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: q['ans'] == true ? Colors.red.withValues(alpha: 0.08) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: q['ans'] == true ? Colors.redAccent : Colors.white12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(q['text'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text("+${q['pts']}đ", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("Y khoa: ${q['why']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ChoiceChip(
                                label: const Text("Không"),
                                selected: q['ans'] == false,
                                onSelected: (sel) {
                                  if (sel) setState(() => q['ans'] = false);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text("Có / Đúng"),
                                selectedColor: Colors.redAccent.withValues(alpha: 0.3),
                                selected: q['ans'] == true,
                                onSelected: (sel) {
                                  if (sel) setState(() => q['ans'] = true);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: currentScore >= 4 ? Colors.redAccent : Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _finish,
              icon: const Icon(Icons.check_circle_outline),
              label: Text("Hoàn thành đánh giá ($currentScore điểm)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÍNH NĂNG 3: BÁO CÁO Y KHOA XUẤT ĐỊNH KỲ (MEDICAL AUDIT REPORT DIALOG)
// =========================================================================
class MedicalAuditReportDialog extends StatelessWidget {
  final ElderlyMedicalProfile profile;
  final List<dynamic> eventHistory;
  final int cdcScore;
  final DateTime? cdcDate;
  final int inactivityEventsCount;
  final int tofHeight;
  final int radarMotion;

  const MedicalAuditReportDialog({
    super.key,
    required this.profile,
    required this.eventHistory,
    required this.cdcScore,
    required this.cdcDate,
    required this.inactivityEventsCount,
    required this.tofHeight,
    required this.radarMotion,
  });

  String _generateReportText() {
    final now = DateTime.now();
    final age = now.year - profile.birthYear;
    final dateStr = "${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return """
======================================================================
BÁO CÁO LÂM SÀNG GIÁM SÁT TÉ NGÃ & VẬN ĐỘNG (FALLGUARD CLINICAL REPORT)
Hệ thống giám sát vi ba Radar FMCW 24GHz & Laser ToF AI ESP32-S3R8
Thời điểm xuất báo cáo: $dateStr
======================================================================

I. THÔNG TIN BỆNH NHÂN & HỒ SƠ Y TẾ
• Họ và tên: ${profile.fullName}
• Tuổi: $age tuổi (Sinh năm ${profile.birthYear} - Giới tính: ${profile.gender})
• Nhóm máu: ${profile.bloodType}
• Cảnh báo thuốc chống đông máu: ${profile.isTakingAnticoagulants ? 'CÓ (Aspirin/Warfarin/Xarelto - CỰC KỲ LƯU Ý)' : 'Không ghi nhận'}
• Bệnh lý nền: ${profile.chronicConditions.join(', ')}
• Đơn thuốc đang sử dụng: ${profile.highRiskMedications.join(', ')}
• Bác sĩ phụ trách: ${profile.attendingDoctorName} (SĐT: ${profile.attendingDoctorPhone})
• Bệnh viện chỉ định: ${profile.hospital}

II. CHỈ SỐ ĐÁNH GIÁ NGUY CƠ TÉ NGÃ (CDC STEADI USA)
• Điểm đánh giá: $cdcScore / 14 điểm
• Phân tầng nguy cơ: ${cdcScore >= 4 ? 'NGUY CƠ CAO (High Fall Risk >= 4)' : 'NGUY CƠ THẤP / TRUNG BÌNH (< 4)'}
• Ngày đánh giá gần nhất: ${cdcDate != null ? '${cdcDate!.day}/${cdcDate!.month}/${cdcDate!.year}' : 'Chưa thực hiện'}

III. THỐNG KÊ SỰ CỐ & HỘP ĐEN NVS (BLACKBOX AUDIT)
• Tổng số vụ té ngã va chạm mạnh ghi nhận: ${eventHistory.where((e) => e['type'] == 1).length} sự cố
• Tổng số sự cố ngã chậm / nằm sàn bất động: ${eventHistory.where((e) => e['type'] == 2).length} sự cố
• Số lần cảnh báo lưu trú bất động trong nhà tắm (>30p): $inactivityEventsCount lần
• Trạng thái hiện tại: Chiều cao ToF $tofHeight mm | Động năng Radar $radarMotion/100

IV. KHUYẾN CÁO LÂM SÀNG DÀNH CHO BÁC SĨ & GIA ĐÌNH
1. Người bệnh có phân tầng nguy cơ ngã ${cdcScore >= 4 ? 'CAO' : 'TRUNG BÌNH'}. Cần kiểm tra huyết áp tư thế nằm và đứng (Orthostatic Hypotension) tại phòng khám.
2. ${profile.isTakingAnticoagulants ? 'ĐẶC BIỆT LƯU Ý: Do bệnh nhân đang điều trị thuốc chống đông, mọi cú ngã va chạm vùng đầu dù chưa xuất hiện triệu chứng ngoài da vẫn bắt buộc chụp CT sọ não trong 24h để loại trừ tụ máu dưới màng cứng muộn.' : 'Duy trì chế độ vận động nhẹ nhàng.'}
3. Kiểm tra môi trường nhà ở: Lắp đặt tay vịn nhà vệ sinh, giữ sàn khô ráo, đảm bảo ánh sáng đèn ngủ tự động bật khi người bệnh thức dậy ban đêm.
======================================================================
""";
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generateReportText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã sao chép toàn bộ báo cáo y khoa vào clipboard!"), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _generateReportText();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Colors.tealAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Báo cáo y tế xuất định kỳ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text("Tóm tắt lâm sàng phục vụ thăm khám Bác sĩ", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    report,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.45),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text("Sao chép Báo cáo"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () {
                      _copyToClipboard(context);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text("Sao chép & Gửi Bác sĩ"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÍNH NĂNG 4: CẢNH BÁO KHẨN CẤP VƯỢT CHẾ ĐỘ IM LẶNG (CRITICAL ALARM MODAL)
// =========================================================================
class CriticalEmergencyAlarmDialog extends StatefulWidget {
  final bool isFall;
  final String? customReason;
  final ElderlyMedicalProfile profile;
  final int tofHeight;
  final int radarMotion;
  final double dropRate;
  final String roomName;
  final VoidCallback onCancelAlarm;
  final VoidCallback onOpenMedicalId;
  final VoidCallback onOpenFirstAid;

  const CriticalEmergencyAlarmDialog({
    super.key,
    this.isFall = true,
    this.customReason,
    required this.profile,
    required this.tofHeight,
    required this.radarMotion,
    required this.dropRate,
    required this.roomName,
    required this.onCancelAlarm,
    required this.onOpenMedicalId,
    required this.onOpenFirstAid,
  });

  @override
  State<CriticalEmergencyAlarmDialog> createState() => _CriticalEmergencyAlarmDialogState();
}

class _CriticalEmergencyAlarmDialogState extends State<CriticalEmergencyAlarmDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _hapticLoopTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    // Vòng lặp rung chấn mạnh & âm thanh cảnh báo vượt chế độ im lặng
    _hapticLoopTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  void dispose() {
    _hapticLoopTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _call115() async {
    final uri = Uri.parse("tel:115");
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  void _callFamily() async {
    final phone = widget.profile.emergencyContact1Phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isNotEmpty) {
      final uri = Uri.parse("tel:$phone");
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (ctx, child) {
        final Color flashColor = Color.lerp(Colors.red.shade900, Colors.amber.shade900, _pulseController.value)!;
        return Dialog(
          backgroundColor: const Color(0xFF140303),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: flashColor, width: 3.5),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Biểu tượng & Nhấp nháy báo động
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2 + 0.3 * _pulseController.value),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 2.5),
                      ),
                      child: const Icon(Icons.emergency, color: Colors.redAccent, size: 48),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      widget.isFall ? "🚨 CẢNH BÁO TÉ NGÃ KHẨN CẤP!" : "CẢNH BÁO BẤT ĐỘNG KÉO DÀI!",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.customReason ?? (widget.isFall
                        ? "Hệ thống AI vừa phát hiện cú ngã va chạm mạnh tại khu vực [${widget.roomName}]!"
                        : "Phát hiện người thân bất động quá lâu trong [${widget.roomName}]. Nghi ngờ ngất xỉu hoặc đột quỵ!"),
                    style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.35),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Bảng thông số tại thời điểm sự cố
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric("V_rơi", "${widget.dropRate.toStringAsFixed(0)} mm/s"),
                        _buildMetric("Độ cao ToF", "${widget.tofHeight} mm"),
                        _buildMetric("Động năng Radar", "${widget.radarMotion}%"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút gọi 115 khẩn cấp
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _call115,
                    icon: const Icon(Icons.phone_in_talk, size: 22),
                    label: const Text("GỌI CẤP CỨU 115 NGAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),

                  // Nút gọi người thân khẩn cấp
                  if (widget.profile.emergencyContact1Phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _callFamily,
                      icon: const Icon(Icons.call, size: 20),
                      label: Text("GỌI NGƯỜI THÂN (${widget.profile.emergencyContact1Name})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onOpenMedicalId();
                          },
                          icon: const Icon(Icons.badge, size: 16),
                          label: const Text("Thẻ Y Tế", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onOpenFirstAid();
                          },
                          icon: const Icon(Icons.medical_services, size: 16),
                          label: const Text("Sơ cứu", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nút xác nhận an toàn & Hủy còi hú
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      _hapticLoopTimer?.cancel();
                      widget.onCancelAlarm();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text("XÁC NHẬN AN TOÀN / TẮT CÒI HÚ", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
      ],
    );
  }
}

// =========================================================================
// TÍNH NĂNG 6: WIDGET TIỆN ÍCH MÀN HÌNH KHÓA & MÀN HÌNH CHÍNH (PREVIEW MODAL)
// =========================================================================
class LockscreenWidgetPreviewDialog extends StatelessWidget {
  final String posture;
  final int tofHeight;
  final int radarMotion;
  final String roomName;
  final String sysState;

  const LockscreenWidgetPreviewDialog({
    super.key,
    required this.posture,
    required this.tofHeight,
    required this.radarMotion,
    required this.roomName,
    required this.sysState,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.widgets, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mô phỏng Widget Màn hình khóa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("iOS Dynamic Island & Android Glance Widget", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),

              // 1. MÔ PHỎNG DYNAMIC ISLAND (iOS 16.1+)
              const Text("1. iOS Dynamic Island & Hoạt động trực tiếp (Live Activity):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: sysState == "ALERT" ? Colors.red : Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.shield, color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "FallGuard: $roomName • An toàn",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text("${tofHeight}mm", style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. MÔ PHỎNG WIDGET MÀN HÌNH KHÓA iOS (2x1)
              const Text("2. Tiện ích màn hình khóa iOS Lock Screen (Widget 2x1):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.health_and_safety, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        const Text("FALL GUARD S3R8", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const Spacer(),
                        Text(posture, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("Người thân đang an toàn tại $roomName", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text("Radar: $radarMotion% • Chiều cao: ${tofHeight}mm • Trực tiếp", style: const TextStyle(fontSize: 10, color: Colors.white60)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. MÔ PHỎNG WIDGET MÀN HÌNH CHÍNH ANDROID (Glance 4x2)
              const Text("3. Tiện ích màn hình chính Android Home Widget (Material You):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900.withValues(alpha: 0.5), Colors.teal.shade900.withValues(alpha: 0.5)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ông An: Trạng thái bình thường", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text("Không phát hiện nguy cơ trượt ngã", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.battery_charging_full, size: 16, color: Colors.greenAccent),
                        const SizedBox(width: 2),
                        const Text("100%", style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                            child: const Center(child: Text("📞 Gọi 115", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                            child: const Center(child: Text("🪪 Thẻ Y Tế", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.tealAccent))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tôi đã hiểu"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
