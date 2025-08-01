// Mrs. Violet Noire - Murder Mystery Book Review Website
// Interactive JavaScript functionality

document.addEventListener('DOMContentLoaded', function() {

    // Mobile Navigation Toggle
    const navToggle = document.querySelector('.nav-toggle');
    const navMenu = document.querySelector('.nav-menu');

    if (navToggle && navMenu) {
        navToggle.addEventListener('click', function() {
            navMenu.classList.toggle('active');
            navToggle.classList.toggle('active');
        });
    }

    // Smooth Scrolling for Navigation Links
    const navLinks = document.querySelectorAll('.nav-link');

    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            const href = this.getAttribute('href');

            if (href.startsWith('#')) {
                e.preventDefault();
                const target = document.querySelector(href);

                if (target) {
                    const offsetTop = target.offsetTop - 80; // Account for fixed header

                    window.scrollTo({
                        top: offsetTop,
                        behavior: 'smooth'
                    });

                    // Close mobile menu if open
                    if (navMenu.classList.contains('active')) {
                        navMenu.classList.remove('active');
                        navToggle.classList.remove('active');
                    }
                }
            }
        });
    });

    // Newsletter Form Handling
    const newsletterForm = document.querySelector('.newsletter-form');

    if (newsletterForm) {
        newsletterForm.addEventListener('submit', function(e) {
            e.preventDefault();

            const emailInput = this.querySelector('input[type="email"]');
            const email = emailInput.value;

            if (email) {
                // Simulate newsletter subscription
                showNotification('Thank you for subscribing to Mrs. Violet Noire\'s newsletter!', 'success');
                emailInput.value = '';
            }
        });
    }

    // Add scroll effects to cards
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

    // Observe all cards for scroll animations
    const cards = document.querySelectorAll('.review-card, .genre-card');
    cards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });

    // Book Rating Stars Interactive Effect
    const ratingBadges = document.querySelectorAll('.rating-badge');

    ratingBadges.forEach(badge => {
        badge.addEventListener('mouseenter', function() {
            this.style.transform = 'scale(1.1) rotate(5deg)';
        });

        badge.addEventListener('mouseleave', function() {
            this.style.transform = 'scale(1) rotate(0deg)';
        });
    });

    // Mystery Card Interactive Effect
    const mysteryCard = document.querySelector('.mystery-card');

    if (mysteryCard) {
        mysteryCard.addEventListener('click', function() {
            // Add a fun click effect
            this.style.animation = 'mysteryReveal 0.6s ease-in-out';

            setTimeout(() => {
                this.style.animation = '';
            }, 600);
        });
    }

    // Genre Cards Interactive Effects
    const genreCards = document.querySelectorAll('.genre-card');

    genreCards.forEach(card => {
        const icon = card.querySelector('.genre-icon');

        card.addEventListener('mouseenter', function() {
            if (icon) {
                icon.style.transform = 'scale(1.2) rotate(10deg)';
                icon.style.transition = 'transform 0.3s ease';
            }
        });

        card.addEventListener('mouseleave', function() {
            if (icon) {
                icon.style.transform = 'scale(1) rotate(0deg)';
            }
        });
    });

    // Typing Effect for Hero Title (Optional Enhancement)
    const heroTitle = document.querySelector('.hero-title');

    if (heroTitle) {
        const originalText = heroTitle.innerHTML;
        const words = originalText.split(' ');

        // Only run typing effect if user prefers reduced motion is not set
        if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
            heroTitle.innerHTML = '';
            let wordIndex = 0;

            function typeWords() {
                if (wordIndex < words.length) {
                    heroTitle.innerHTML += words[wordIndex] + ' ';
                    wordIndex++;
                    setTimeout(typeWords, 200);
                }
            }

            // Start typing effect after a short delay
            setTimeout(typeWords, 500);
        }
    }

    // Header Scroll Effect
    const header = document.querySelector('.header');
    let lastScrollTop = 0;

    window.addEventListener('scroll', function() {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

        if (scrollTop > lastScrollTop && scrollTop > 100) {
            // Scrolling down
            header.style.transform = 'translateY(-100%)';
        } else {
            // Scrolling up
            header.style.transform = 'translateY(0)';
        }

        lastScrollTop = scrollTop;
    });

    // Add transition to header
    if (header) {
        header.style.transition = 'transform 0.3s ease-in-out';
    }

    // Read More Button Effects
    const readMoreLinks = document.querySelectorAll('.read-more');

    readMoreLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();

            // Simulate opening full review
            showNotification('Full review coming soon! 📚', 'info');
        });
    });

    // Book Cover Hover Effects
    const bookCovers = document.querySelectorAll('.book-cover');

    bookCovers.forEach(cover => {
        cover.addEventListener('mouseenter', function() {
            const placeholder = this.querySelector('.cover-placeholder');
            if (placeholder) {
                placeholder.style.transform = 'scale(1.1) rotate(5deg)';
                placeholder.style.transition = 'transform 0.3s ease';
            }
        });

        cover.addEventListener('mouseleave', function() {
            const placeholder = this.querySelector('.cover-placeholder');
            if (placeholder) {
                placeholder.style.transform = 'scale(1) rotate(0deg)';
            }
        });
    });
});

// Utility Functions

// Show notification messages
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    const span = document.createElement('span');
    span.textContent = message;

    const closeBtn = document.createElement('button');
    closeBtn.className = 'notification-close';
    closeBtn.innerHTML = '&times;';

    notification.appendChild(span);
    notification.appendChild(closeBtn);

    // Add notification styles
    notification.style.cssText = `
        position: fixed;
        top: 100px;
        right: 20px;
        background: ${type === 'success' ? '#27ae60' : type === 'error' ? '#e74c3c' : '#3498db'};
        color: white;
        padding: 1rem 1.5rem;
        border-radius: 6px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        z-index: 10000;
        display: flex;
        align-items: center;
        gap: 1rem;
        max-width: 300px;
        animation: slideInRight 0.3s ease;
    `;

    document.body.appendChild(notification);

    // Close button functionality
    closeBtn.style.cssText = `
        background: none;
        border: none;
        color: white;
        font-size: 1.5rem;
        cursor: pointer;
        padding: 0;
        line-height: 1;
    `;

    closeBtn.addEventListener('click', function() {
        notification.remove();
    });

    // Auto-remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.remove();
        }
    }, 5000);
}

// Add CSS animations dynamically
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInRight {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }

    @keyframes mysteryReveal {
        0% { transform: rotate(-2deg) scale(1); }
        25% { transform: rotate(0deg) scale(1.05); }
        50% { transform: rotate(2deg) scale(1.1); }
        75% { transform: rotate(0deg) scale(1.05); }
        100% { transform: rotate(-2deg) scale(1); }
    }

    .nav-menu.active {
        display: flex !important;
        flex-direction: column;
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background: white;
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        padding: 1rem;
        gap: 1rem;
    }

    .nav-toggle.active span:nth-child(1) {
        transform: rotate(45deg) translate(6px, 6px);
    }

    .nav-toggle.active span:nth-child(2) {
        opacity: 0;
    }

    .nav-toggle.active span:nth-child(3) {
        transform: rotate(-45deg) translate(6px, -6px);
    }

    @media (max-width: 768px) {
        .nav-menu {
            display: none;
        }
    }
`;

document.head.appendChild(style);
