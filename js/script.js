// Mrs. Violet Noire Website JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Smooth scrolling for navigation links
    const navLinks = document.querySelectorAll('.nav-link');

    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();

            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);

            if (targetSection) {
                const headerHeight = document.querySelector('.header').offsetHeight;
                const targetPosition = targetSection.offsetTop - headerHeight;

                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });

    // Newsletter form handling
    const newsletterForm = document.querySelector('.newsletter-form');

    if (newsletterForm) {
        newsletterForm.addEventListener('submit', function(e) {
            e.preventDefault();

            const emailInput = this.querySelector('input[type="email"]');
            const email = emailInput.value.trim();

            if (email) {
                // Simulate newsletter signup
                alert('Thank you for subscribing! You\'ll receive notifications about new mystery novel reviews.');
                emailInput.value = '';
            }
        });
    }

    // Header scroll effect
    const header = document.querySelector('.header');
    let lastScrollY = window.scrollY;

    window.addEventListener('scroll', function() {
        const currentScrollY = window.scrollY;

        if (currentScrollY > 100) {
            header.style.background = 'rgba(255, 255, 255, 0.95)';
            header.style.backdropFilter = 'blur(10px)';
        } else {
            header.style.background = '#ffffff';
            header.style.backdropFilter = 'none';
        }

        lastScrollY = currentScrollY;
    });

    // Book hover animations
    const reviewCards = document.querySelectorAll('.review-card');

    reviewCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-8px) scale(1.02)';
        });

        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });

    // Intersection Observer for animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Observe sections for scroll animations
    const sections = document.querySelectorAll('section');
    sections.forEach(section => {
        section.style.opacity = '0';
        section.style.transform = 'translateY(30px)';
        section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(section);
    });

    // Book stack animation enhancement
    const bookStack = document.querySelector('.book-stack');
    if (bookStack) {
        const books = bookStack.querySelectorAll('.book');

        books.forEach((book, index) => {
            book.style.animation = `float ${3 + index * 0.5}s ease-in-out infinite`;
            book.style.animationDelay = `${index * 0.2}s`;
        });
    }

    // Add floating animation keyframes
    const style = document.createElement('style');
    style.textContent = `
        @keyframes float {
            0%, 100% { transform: translateY(0px) rotate(var(--rotation, 0deg)); }
            50% { transform: translateY(-10px) rotate(var(--rotation, 0deg)); }
        }

        .book-1 { --rotation: -5deg; }
        .book-2 { --rotation: 2deg; }
        .book-3 { --rotation: -2deg; }
    `;
    document.head.appendChild(style);

    // Genre card interactions
    const genreCards = document.querySelectorAll('.genre-card');

    genreCards.forEach(card => {
        card.addEventListener('click', function() {
            const genre = this.querySelector('h3').textContent;
            alert(`Exploring ${genre} reviews... (This would navigate to the ${genre} section)`);
        });
    });

    // Reading progress indicator (for future blog posts)
    function createReadingProgress() {
        const progressBar = document.createElement('div');
        progressBar.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 0%;
            height: 3px;
            background: linear-gradient(90deg, #8b4a6b, #d4af37);
            z-index: 9999;
            transition: width 0.3s ease;
        `;
        document.body.appendChild(progressBar);

        window.addEventListener('scroll', function() {
            const windowHeight = window.innerHeight;
            const documentHeight = document.documentElement.scrollHeight - windowHeight;
            const scrolled = window.scrollY;
            const progress = (scrolled / documentHeight) * 100;

            progressBar.style.width = progress + '%';
        });
    }

    createReadingProgress();

    // Add some personality with random book recommendations
    const bookRecommendations = [
        'Have you read \'The Seven Deaths of Evelyn Hardcastle\' by Stuart Turton?',
        'I recommend \'The Sweetness at the Bottom of the Pie\' by Alan Bradley for cozy mystery lovers.',
        'For Nordic Noir fans, try \'The Girl with the Dragon Tattoo\' by Stieg Larsson.',
        'Agatha Christie\'s \'And Then There Were None\' is a timeless classic worth revisiting.'
    ];

    // Show random recommendation (could be triggered by various events)
    function showRandomRecommendation() {
        const recommendation = bookRecommendations[Math.floor(Math.random() * bookRecommendations.length)];
        console.log(`📚 Mrs. Noire's Recommendation: ${recommendation}`);
    }

    // Trigger recommendation after user has been on site for a while
    setTimeout(showRandomRecommendation, 30000); // 30 seconds

    console.log('🔍 Welcome to Mrs. Violet Noire\'s literary world of mystery and suspense!');
});
