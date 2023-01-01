module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      flex: {
        '3/2': '1.5 1.5 0%',
      },
    },
  },
  plugins: [require("@tailwindcss/forms")],
};
