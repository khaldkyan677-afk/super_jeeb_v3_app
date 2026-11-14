const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

const mailOptions = {
  from: process.env.EMAIL_USER,
  to: 'khaled20010405@gmail.com',
  subject: 'اختبار إرسال البريد - Super Jeeb',
  text: 'إذا وصلتك هذه الرسالة، فهذا يعني أن إعدادات البريد تعمل بنجاح 100%!',
};

transporter.sendMail(mailOptions, (error, info) => {
  if (error) {
    console.log('❌ فشل الإرسال:', error.message);
  } else {
    console.log('✅ تم إرسال البريد بنجاح:', info.response);
  }
});
