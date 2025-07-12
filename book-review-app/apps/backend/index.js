const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const MONGO_URL = process.env.MONGO_URL || 'mongodb://mongodb:27017/bookdb';

// Connect to MongoDB
mongoose.connect(MONGO_URL)
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err));

// Define Book schema and model
const bookSchema = new mongoose.Schema({
  title: String,
  author: String,
  reviews: [String]
});
const Book = mongoose.model('Book', bookSchema);

// Routes
app.get('/api/books', async (req, res) => {
  try {
    console.log('GET /api/books - Fetching books from database');
    const books = await Book.find();
    console.log(`Found ${books.length} books`);
    res.json(books);
  } catch (error) {
    console.error('Error fetching books:', error);
    res.status(500).json({ error: 'Failed to fetch books' });
  }
});

app.post('/api/books', async (req, res) => {
  try {
    console.log('POST /api/books - Creating new book:', req.body);
    const book = new Book(req.body);
    await book.save();
    console.log('Book created successfully:', book);
    res.status(201).json(book);
  } catch (error) {
    console.error('Error creating book:', error);
    res.status(500).json({ error: 'Failed to create book' });
  }
});

app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));
