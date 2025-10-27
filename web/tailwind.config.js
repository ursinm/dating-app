/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'purple-primary': '#B258BD',
        'purple-light': '#EEE2F5',
        'purple-grey': '#625b71',
        'pink-accent': '#7D5260',
      }
    },
  },
  plugins: [],
}
