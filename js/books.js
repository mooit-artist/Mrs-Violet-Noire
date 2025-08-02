// Book data parser and renderer for Mrs. Violet Noire
class BookLibrary {
    constructor() {
        this.books = [];
        this.featuredBooks = [];
        this.genreStats = {};
    }

    // Parse CSV data from Goodreads export
    parseCSVData(csvText) {
        const lines = csvText.split('\n');
        const headers = lines[0].split(',');

        for (let i = 1; i < lines.length; i++) {
            if (lines[i].trim() === '') continue;

            const values = this.parseCSVLine(lines[i]);
            if (values.length < headers.length) continue;

            const book = {};
            headers.forEach((header, index) => {
                book[header.trim()] = values[index] ? values[index].trim() : '';
            });

            // Clean up the data
            this.cleanBookData(book);
            this.books.push(book);
        }

        this.processBooksData();
    }

    // Parse CSV line handling quoted fields
    parseCSVLine(line) {
        const result = [];
        let current = '';
        let inQuotes = false;

        for (let i = 0; i < line.length; i++) {
            const char = line[i];

            if (char === '"') {
                inQuotes = !inQuotes;
            } else if (char === ',' && !inQuotes) {
                result.push(current);
                current = '';
            } else {
                current += char;
            }
        }
        result.push(current);

        return result;
    }

    // Clean and normalize book data
    cleanBookData(book) {
        // Remove quotes and clean ISBN fields
        book.ISBN = book.ISBN.replace(/[="]/g, '');
        book.ISBN13 = book.ISBN13.replace(/[="]/g, '');

        // Parse ratings
        book['My Rating'] = parseInt(book['My Rating']) || 0;
        book['Average Rating'] = parseFloat(book['Average Rating']) || 0;

        // Parse publication year
        book['Year Published'] = parseInt(book['Year Published']) || 0;

        // Determine genre based on title, author, and content patterns
        book.inferredGenre = this.inferGenre(book);

        // Parse dates
        if (book['Date Read']) {
            book.parsedDateRead = new Date(book['Date Read']);
        }
        if (book['Date Added']) {
            book.parsedDateAdded = new Date(book['Date Added']);
        }
    }

    // Infer genre from book data
    inferGenre(book) {
        const title = book.Title.toLowerCase();
        const author = book.Author.toLowerCase();

        // Mystery/Crime patterns
        if (title.includes('murder') || title.includes('mystery') || title.includes('detective') ||
            title.includes('crime') || title.includes('kill') || title.includes('death') ||
            title.includes('stranger') || title.includes('dark') || title.includes('night') ||
            title.includes('gone') || title.includes('missing') || title.includes('lies') ||
            author.includes('mcfadden') || author.includes('sager') || author.includes('lapena') ||
            author.includes('jewell') || author.includes('hillier') || author.includes('marrs')) {
            return 'Mystery & Crime';
        }

        // Psychological Thriller patterns
        if (title.includes('psychological') || title.includes('mind') || title.includes('perfect') ||
            title.includes('secret') || title.includes('behind') || title.includes('house') ||
            title.includes('family') || title.includes('wife') || title.includes('husband') ||
            author.includes('paris') || author.includes('kubica') || author.includes('feeney')) {
            return 'Psychological Thriller';
        }

        // Domestic/Family Thriller
        if (title.includes('family') || title.includes('home') || title.includes('neighbor') ||
            title.includes('marriage') || title.includes('couple') || title.includes('guest') ||
            title.includes('housemaid') || title.includes('tenant')) {
            return 'Domestic Thriller';
        }

        // Historical patterns
        if (title.includes('historical') || book['Year Published'] < 2000 ||
            title.includes('war') || title.includes('past') || author.includes('hannah')) {
            return 'Historical Fiction';
        }

        // Suspense/General Thriller
        return 'Suspense & Thriller';
    }

    // Process books to create featured selections and stats
    processBooksData() {
        // Get books that have been read
        const readBooks = this.books.filter(book =>
            book['Exclusive Shelf'] === 'read' && book['Average Rating'] > 3.5
        );

        // Sort by rating and recency for featured books
        this.featuredBooks = readBooks
            .filter(book => book['Average Rating'] >= 3.8)
            .sort((a, b) => {
                // Priority: My Rating > Average Rating > Recent reads
                if (a['My Rating'] !== b['My Rating']) {
                    return b['My Rating'] - a['My Rating'];
                }
                if (Math.abs(a['Average Rating'] - b['Average Rating']) > 0.1) {
                    return b['Average Rating'] - a['Average Rating'];
                }
                return (b.parsedDateRead || b.parsedDateAdded) - (a.parsedDateRead || a.parsedDateAdded);
            })
            .slice(0, 6);

        // Calculate genre statistics
        this.calculateGenreStats();
    }

    // Calculate genre statistics
    calculateGenreStats() {
        this.genreStats = {};

        this.books.forEach(book => {
            if (book['Exclusive Shelf'] === 'read') {
                const genre = book.inferredGenre;
                if (!this.genreStats[genre]) {
                    this.genreStats[genre] = {
                        count: 0,
                        totalRating: 0,
                        books: []
                    };
                }
                this.genreStats[genre].count++;
                this.genreStats[genre].totalRating += book['Average Rating'];
                this.genreStats[genre].books.push(book);
            }
        });

        // Calculate average ratings for each genre
        Object.keys(this.genreStats).forEach(genre => {
            const stats = this.genreStats[genre];
            stats.averageRating = stats.totalRating / stats.count;
        });
    }

    // Render featured books to the reviews section
    renderFeaturedBooks() {
        const reviewsGrid = document.querySelector('.reviews-grid');
        if (!reviewsGrid) return;

        reviewsGrid.innerHTML = '';

        this.featuredBooks.forEach((book, index) => {
            const bookCard = this.createBookCard(book, index);
            reviewsGrid.appendChild(bookCard);
        });
    }

    // Create a book card element
    createBookCard(book, index) {
        const card = document.createElement('article');
        card.className = 'review-card';

        const coverEmojis = ['📚', '📖', '📕', '📘', '📗', '📙'];
        const coverEmoji = coverEmojis[index % coverEmojis.length];

        // Format rating
        const displayRating = book['My Rating'] > 0 ? book['My Rating'] : book['Average Rating'];
        const ratingText = `${displayRating.toFixed(1)}/5`;

        // Format date
        const dateRead = book.parsedDateRead || book.parsedDateAdded;
        const dateText = dateRead ? dateRead.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        }) : 'Recently read';

        // Create review excerpt based on genre and rating
        const excerpt = this.generateReviewExcerpt(book);

        // Create elements safely without innerHTML
        const bookCover = document.createElement('div');
        bookCover.className = 'book-cover';

        const coverPlaceholder = document.createElement('div');
        coverPlaceholder.className = 'cover-placeholder';
        coverPlaceholder.textContent = coverEmoji;

        const ratingBadge = document.createElement('div');
        ratingBadge.className = 'rating-badge';
        ratingBadge.textContent = ratingText;

        bookCover.appendChild(coverPlaceholder);
        bookCover.appendChild(ratingBadge);

        const reviewContent = document.createElement('div');
        reviewContent.className = 'review-content';

        const bookTitle = document.createElement('h3');
        bookTitle.className = 'book-title';
        bookTitle.textContent = book.Title;

        const bookAuthor = document.createElement('p');
        bookAuthor.className = 'book-author';
        bookAuthor.textContent = `by ${book.Author}`;

        const bookGenre = document.createElement('p');
        bookGenre.className = 'book-genre';
        bookGenre.textContent = book.inferredGenre;

        const reviewExcerpt = document.createElement('p');
        reviewExcerpt.className = 'review-excerpt';
        reviewExcerpt.textContent = excerpt;

        const reviewMeta = document.createElement('div');
        reviewMeta.className = 'review-meta';

        const reviewDate = document.createElement('span');
        reviewDate.className = 'review-date';
        reviewDate.textContent = dateText;

        const readMore = document.createElement('a');
        readMore.href = '#';
        readMore.className = 'read-more';
        readMore.textContent = 'Read Full Review';
        readMore.setAttribute('data-book-id', book['Book Id']);

        reviewMeta.appendChild(reviewDate);
        reviewMeta.appendChild(readMore);

        reviewContent.appendChild(bookTitle);
        reviewContent.appendChild(bookAuthor);
        reviewContent.appendChild(bookGenre);
        reviewContent.appendChild(reviewExcerpt);
        reviewContent.appendChild(reviewMeta);

        card.appendChild(bookCover);
        card.appendChild(reviewContent);

        return card;
    }

    // Generate review excerpt based on book data
    generateReviewExcerpt(book) {
        const rating = book['My Rating'] > 0 ? book['My Rating'] : book['Average Rating'];
        const genre = book.inferredGenre;
        const author = book.Author;

        const excerpts = {
            high: [
                `A masterfully crafted ${genre.toLowerCase()} that kept me turning pages late into the night. ${author} delivers exceptional character development and a plot that never loses momentum.`,
                `Outstanding work that showcases why ${author} is a master of the genre. The intricate plotting and atmospheric writing make this a standout in ${genre.toLowerCase()}.`,
                `Brilliantly executed with twists that I never saw coming. ${author} has created something truly special that will stay with readers long after the final page.`,
                `A tour de force that perfectly balances suspense with deep character exploration. This is ${genre.toLowerCase()} at its finest.`
            ],
            medium: [
                `A solid entry in the ${genre.toLowerCase()} genre with engaging characters and a well-paced plot. ${author} crafts an entertaining read that kept me invested throughout.`,
                `Well-written and atmospheric, this book delivers on its promises. While not groundbreaking, it's a satisfying read for fans of ${genre.toLowerCase()}.`,
                `${author} creates a compelling narrative with good character development. A reliable choice for readers seeking quality ${genre.toLowerCase()}.`,
                'An engaging thriller with enough twists to keep readers guessing. The writing is solid and the pacing well-maintained.'
            ],
            low: [
                `While this book has its moments, it doesn't quite reach the heights of ${author}'s best work. Still worth reading for fans of ${genre.toLowerCase()}.`,
                'A decent read with some interesting elements, though the execution could have been stronger. Has potential but falls short of expectations.',
                `Mixed feelings about this one. Some strong points but overall doesn't stand out in the crowded ${genre.toLowerCase()} field.`
            ]
        };

        let category;
        if (rating >= 4.0) category = 'high';
        else if (rating >= 3.0) category = 'medium';
        else category = 'low';

        const options = excerpts[category];
        return options[Math.floor(Math.random() * options.length)];
    }

    // Render genre statistics
    renderGenreStats() {
        const genresGrid = document.querySelector('.genres-grid');
        if (!genresGrid) return;

        genresGrid.innerHTML = '';

        // Sort genres by count
        const sortedGenres = Object.entries(this.genreStats)
            .sort(([,a], [,b]) => b.count - a.count)
            .slice(0, 6); // Show top 6 genres

        const genreIcons = {
            'Mystery & Crime': '🔍',
            'Psychological Thriller': '🧠',
            'Domestic Thriller': '🏠',
            'Suspense & Thriller': '⚡',
            'Historical Fiction': '📜',
            'Contemporary Fiction': '📖'
        };

        sortedGenres.forEach(([genre, stats]) => {
            const genreCard = document.createElement('div');
            genreCard.className = 'genre-card';

            const icon = genreIcons[genre] || '📚';
            const avgRating = stats.averageRating.toFixed(1);

            const genreIcon = document.createElement('div');
            genreIcon.className = 'genre-icon';
            genreIcon.textContent = icon;

            const genreTitle = document.createElement('h3');
            genreTitle.textContent = genre;

            const genreDesc = document.createElement('p');
            genreDesc.textContent = `Exploring the depths of ${genre.toLowerCase()} with carefully curated reviews and recommendations.`;

            const genreCount = document.createElement('div');
            genreCount.className = 'genre-count';
            genreCount.textContent = `${stats.count} books reviewed`;

            const genreRating = document.createElement('div');
            genreRating.className = 'genre-rating';
            genreRating.textContent = `Avg. ${avgRating}⭐`;

            genreCard.appendChild(genreIcon);
            genreCard.appendChild(genreTitle);
            genreCard.appendChild(genreDesc);
            genreCard.appendChild(genreCount);
            genreCard.appendChild(genreRating);

            genresGrid.appendChild(genreCard);
        });
    }

    // Update reading statistics in about section
    updateReadingStats() {
        const totalBooks = this.books.filter(book => book['Exclusive Shelf'] === 'read').length;
        const currentlyReading = this.books.filter(book => book['Exclusive Shelf'] === 'currently-reading').length;
        // const toRead = this.books.filter(book => book['Exclusive Shelf'] === 'to-read').length; // Unused for now

        // Update credentials section if it exists
        const credentials = document.querySelector('.credentials');
        if (credentials) {
            credentials.innerHTML = '';

            const totalBooksCredential = document.createElement('div');
            totalBooksCredential.className = 'credential';
            const totalBooksStrong = document.createElement('strong');
            totalBooksStrong.textContent = totalBooks.toString();
            const totalBooksSpan = document.createElement('span');
            totalBooksSpan.textContent = 'Books Reviewed';
            totalBooksCredential.appendChild(totalBooksStrong);
            totalBooksCredential.appendChild(totalBooksSpan);

            const genresCredential = document.createElement('div');
            genresCredential.className = 'credential';
            const genresStrong = document.createElement('strong');
            genresStrong.textContent = Object.keys(this.genreStats).length.toString();
            const genresSpan = document.createElement('span');
            genresSpan.textContent = 'Genres Explored';
            genresCredential.appendChild(genresStrong);
            genresCredential.appendChild(genresSpan);

            const currentlyReadingCredential = document.createElement('div');
            currentlyReadingCredential.className = 'credential';
            const currentlyReadingStrong = document.createElement('strong');
            currentlyReadingStrong.textContent = currentlyReading.toString();
            const currentlyReadingSpan = document.createElement('span');
            currentlyReadingSpan.textContent = 'Currently Reading';
            currentlyReadingCredential.appendChild(currentlyReadingStrong);
            currentlyReadingCredential.appendChild(currentlyReadingSpan);

            credentials.appendChild(totalBooksCredential);
            credentials.appendChild(genresCredential);
            credentials.appendChild(currentlyReadingCredential);
        }
    }

    // Initialize the library
    async init() {
        try {
            const response = await fetch('goodreads_library_export.csv');
            const csvText = await response.text();
            this.parseCSVData(csvText);

            // Render all sections
            this.renderFeaturedBooks();
            this.renderGenreStats();
            this.updateReadingStats();

            console.log(`Loaded ${this.books.length} books from Goodreads library`);
            console.log(`Featuring ${this.featuredBooks.length} top-rated books`);

        } catch (error) {
            console.error('Error loading book data:', error);
            // Fall back to existing placeholder content
        }
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const library = new BookLibrary();
    library.init();
});

// Export for potential use in other scripts
window.BookLibrary = BookLibrary;
