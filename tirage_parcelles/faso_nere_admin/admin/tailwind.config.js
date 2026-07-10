/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        bg:       '#0E0B1E',
        surface:  '#1A1535',
        surface2: '#231D45',
        card:     '#2A2350',
        gold:     '#F5A623',
        goldDark: '#B87A10',
        purple:   '#7B5EA7',
        border:   '#3A3260',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
    },
  },
  plugins: [],
}