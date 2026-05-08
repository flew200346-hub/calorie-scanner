// ============================================================================
// thai_food_names.dart — แม็ป label จาก tflite → ชื่ออาหารภาษาไทย
// ----------------------------------------------------------------------------
// labels.txt เก็บชื่อ English transliterated เช่น "Pad-Thai", "Green-Curry"
// ใช้ที่ scan_page._runAnalysis: เมื่อ tflite ระบุได้ ก่อนถาม Gemini
// nutrition + ก่อนแสดงให้ user → เรียก labelToThai() เพื่อแปลง
// เพิ่มเมนูใหม่: เพิ่มทั้งใน labels.txt (ตอน train model) + map ตรงนี้
// ============================================================================

/// Maps TFLite label names (from assets/labels.txt) to Thai display names.
const Map<String, String> thaiFoodNames = {
  'BBQ-Pork-Rice': 'ข้าวหมูแดง',
  'Bitter-Melon-Soup': 'แกงจืดมะระ',
  'Chicken-Biryani': 'ข้าวหมกไก่',
  'Chicken-Rice': 'ข้าวมันไก่',
  'Curried-Fish-Cake': 'ทอดมันปลา',
  'Dipping-sauce': 'น้ำจิ้ม',
  'Dumpling': 'ขนมจีบ',
  'Eggs-Stewed': 'ไข่พะโล้',
  'Fried-Chicken': 'ไก่ทอด',
  'Fried-Egg': 'ไข่ดาว',
  'Fried-Noodle-in-Gravy-Sauce': 'ราดหน้า',
  'Fried-Oysters': 'หอยทอด',
  'Fried-Rice-with-Shrimp-Paste': 'ข้าวคลุกกะปิ',
  'Green-Curry': 'แกงเขียวหวาน',
  'Grill-Shrimp': 'กุ้งเผา',
  'Grilled-Pork-Neck': 'คอหมูย่าง',
  'Kai-look-khei': 'ไข่ลูกเขย',
  'Kai-Yang': 'ไก่ย่าง',
  'Kua-Jab-Nam-Khon': 'ก๋วยจั๊บน้ำข้น',
  'Massaman-Curry': 'แกงมัสมั่น',
  'Omelet': 'ไข่เจียว',
  'Pad-Kaprao': 'ผัดกะเพรา',
  'Pad-Thai': 'ผัดไทย',
  'Papaya-Salad': 'ส้มตำ',
  'Poo-Pad-Pongali': 'ปูผัดผงกะหรี่',
  'Pork Satay': 'หมูสะเต๊ะ',
  'Pork-porridge': 'โจ๊กหมู',
  'Pork-with-Garlic': 'หมูกระเทียม',
  'Roast-fish': 'ปลาเผา',
  'Spicy-Mincing-Pork-Salad': 'ลาบหมู',
  'Stewed-Pork-Leg-Rice': 'ข้าวขาหมู',
  'Stir-fried-Kale-with-Crispy-Pork': 'คะน้าหมูกรอบ',
  'Stir-fried-Morning-Glory': 'ผัดผักบุ้ง',
  'Stir-fried-Noodles-in-Soy-Sauce': 'ผัดซีอิ๊ว',
  'Thai-clear-soup': 'แกงจืด',
  'Thai-Noodles-with-Pork-and-Blood-Soup': 'ก๋วยเตี๋ยวเรือ',
  'Yum-Woon-Sen': 'ยำวุ้นเส้น',
};

String labelToThai(String label) =>
    thaiFoodNames[label] ?? label.replaceAll('-', ' ');
