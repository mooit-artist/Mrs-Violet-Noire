// theme-switcher.js: Simple theme switcher for personal use


function setTheme(themeName, save = true) {
    const head = document.head;
    let themeLink = document.getElementById('theme-link');
    if (!themeLink) {
        themeLink = document.createElement('link');
        themeLink.rel = 'stylesheet';
        themeLink.id = 'theme-link';
        head.appendChild(themeLink);
    }
    if (themeName === 'default') {
        themeLink.href = 'css/theme-default.css';
    } else if (themeName === 'dark-academia') {
        themeLink.href = 'css/theme-dark-academia.css';
    } else if (themeName === 'light-academia') {
        themeLink.href = 'css/theme-light-academia.css';
    }
    if (save) {
        localStorage.setItem('mrsVioletTheme', themeName);
    }
}

function getSystemTheme() {
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
        return 'dark-academia';
    } else {
        return 'light-academia';
    }
}

function loadTheme() {
    const saved = localStorage.getItem('mrsVioletTheme');
    if (saved) {
        setTheme(saved, false);
    } else {
        setTheme(getSystemTheme(), false);
    }
}

document.addEventListener('DOMContentLoaded', loadTheme);

// For manual switching in browser console:
// setTheme('default');
// setTheme('dark-academia');
// setTheme('light-academia');
