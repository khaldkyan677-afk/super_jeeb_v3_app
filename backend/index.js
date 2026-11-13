const express = require('express');
const { Pool } = require('pg');
const dotenv = require('dotenv');
const cors = require('cors');
const nodemailer = require('nodemailer');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// إعداد البريد الإلكتروني (Nodemailer)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER, // بريدك الإلكتروني
    pass: process.env.EMAIL_PASS, // كلمة مرور التطبيق
  },
});

app.get('/', (req, res) => {
  res.json({ message: 'Super Jeeb API is running!' });
});

// تسجيل مستخدم جديد
app.post('/api/auth/register', async (req, res) => {
  const { full_name, email, phone, password } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO users (full_name, email, phone, role) VALUES ($1, $2, $3, $4) RETURNING id, full_name, email',
      [full_name, email, phone, 'client']
    );
    res.status(201).json({ message: 'User registered successfully!', user: result.rows[0] });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// تسجيل الدخول
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    res.status(200).json({ message: 'Login successful!', user: result.rows[0] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// نسيت كلمة المرور (إرسال كود OTP)
app.post('/api/auth/forgot-password', async (req, res) => {
  const { email } = req.body;
  try {
    // 1. التحقق من وجود المستخدم
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // 2. توليد كود عشوائي (6 أرقام)
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // 3. حفظ الكود في قاعدة البيانات (سنحتاج إلى جدول مؤقت، أو حفظه في حقل)
    // للتبسيط، سنرسله فقط الآن (في مشروع حقيقي، يجب حفظه للتحقق)
    
    // 4. إرسال البريد الإلكتروني
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'إعادة تعيين كلمة المرور - سوبر جيب',
      text: `كود إعادة تعيين كلمة المرور الخاص بك هو: ${otp}`,
    };

    await transporter.sendMail(mailOptions);

    res.status(200).json({ message: 'OTP sent successfully!' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
