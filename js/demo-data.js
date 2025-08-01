// Sample data update for demonstration
// This will show how your actual Goodreads data populates the site

console.log('🔍 Mrs. Violet Noire Library Loading...');

// Sample of your highly-rated books for immediate display
const sampleFeaturedBooks = [
    {
        title: "Look Closer",
        author: "David Ellis",
        myRating: 5.0,
        avgRating: 4.17,
        genre: "Mystery & Crime",
        excerpt: "A masterfully crafted mystery that kept me turning pages late into the night. Ellis delivers exceptional character development and a plot that never loses momentum. ⭐⭐⭐⭐⭐"
    },
    {
        title: "Hidden Pictures",
        author: "Jason Rekulak",
        myRating: 5.0,
        avgRating: 4.16,
        genre: "Horror Mystery",
        excerpt: "Outstanding work that showcases why Rekulak is a master of the genre. The intricate plotting and atmospheric writing make this a standout in horror mystery. ⭐⭐⭐⭐⭐"
    },
    {
        title: "The Drowning Woman",
        author: "Robyn Harding",
        myRating: 5.0,
        avgRating: 4.04,
        genre: "Psychological Thriller",
        excerpt: "Brilliantly executed with twists that I never saw coming. Harding has created something truly special that will stay with readers long after the final page. ⭐⭐⭐⭐⭐"
    },
    {
        title: "The Push",
        author: "Ashley Audrain",
        myRating: 4.0,
        avgRating: 4.04,
        genre: "Psychological Thriller",
        excerpt: "A tour de force that perfectly balances suspense with deep character exploration. This is psychological thriller at its finest. ⭐⭐⭐⭐"
    },
    {
        title: "The Housemaid",
        author: "Freida McFadden",
        myRating: 0, // No personal rating
        avgRating: 4.29,
        genre: "Domestic Thriller",
        excerpt: "A solid entry in the domestic thriller genre with engaging characters and a well-paced plot. McFadden crafts an entertaining read that kept me invested throughout."
    },
    {
        title: "The Night She Disappeared",
        author: "Lisa Jewell",
        myRating: 0, // No personal rating
        avgRating: 4.09,
        genre: "Mystery & Crime",
        excerpt: "Well-written and atmospheric, this book delivers on its promises. While not groundbreaking, it's a satisfying read for fans of mystery & crime."
    }
];// Your most-read authors based on the CSV data
const topAuthors = [
    { name: "Freida McFadden", bookCount: 11, avgRating: 4.05 },
    { name: "Lisa Jewell", bookCount: 6, avgRating: 3.97 },
    { name: "John Marrs", bookCount: 4, avgRating: 4.04 },
    { name: "Shari Lapena", bookCount: 6, avgRating: 3.77 },
    { name: "B.A. Paris", bookCount: 4, avgRating: 3.74 },
    { name: "Rachel Caine", bookCount: 4, avgRating: 4.19 }
];

// Your reading statistics from the CSV
const readingStats = {
    totalBooksRead: 89,
    currentlyReading: 0,
    toRead: 1,
    personallyRated: 4, // You rated 4 books personally!
    fiveStarBooks: 3,   // Look Closer, Hidden Pictures, The Drowning Woman
    fourStarBooks: 1,   // The Push
    averagePersonalRating: 4.75, // (5+5+5+4)/4
    averageRating: 3.89,
    totalAuthors: 65,
    topGenres: [
        { name: "Mystery & Crime", count: 35 },
        { name: "Psychological Thriller", count: 28 },
        { name: "Domestic Thriller", count: 15 },
        { name: "Suspense & Thriller", count: 11 }
    ]
};

console.log(`📚 Library Stats:
• ${readingStats.totalBooksRead} books read
• ${readingStats.personallyRated} books YOU personally rated (avg: ${readingStats.averagePersonalRating}⭐)
• ${readingStats.fiveStarBooks} five-star favorites + ${readingStats.fourStarBooks} four-star pick
• ${readingStats.totalAuthors} authors explored
• Top genre: ${readingStats.topGenres[0].name} (${readingStats.topGenres[0].count} books)
• Favorite authors: ${topAuthors.slice(0,3).map(a => a.name).join(', ')}`);

console.log('⭐ YOUR PERSONAL 5-STAR FAVORITES:');
console.log('• Look Closer by David Ellis');
console.log('• Hidden Pictures by Jason Rekulak');
console.log('• The Drowning Woman by Robyn Harding');
console.log('✨ Your Goodreads data will automatically populate the featured reviews, prioritizing YOUR ratings!');
