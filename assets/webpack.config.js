const path = require('path')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const TerserPlugin = require('terser-webpack-plugin')
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')

module.exports = (env, options) => {
  const devMode = options.mode !== 'production'

  return {
    entry: {
      main: path.resolve(__dirname, './scripts/main.js')
    },

    output: {
      filename: 'main.js',
      path: path.resolve(__dirname, '../priv/static/scripts'),
      publicPath: '/scripts/'
    },

    devtool: devMode ? 'source-map' : undefined,

    module: {
      rules: [{
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      }, {
        test: /\.[s]?css$/,
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader',
          'postcss-loader',
          'sass-loader'
        ]
      }, {
        test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
        use: {
          loader: 'file-loader',
          options: {
            name: '[name].[ext]',
            outputPath: 'fonts/'
          }
        }
      }]
    },

    optimization: {
      minimizer: [
        new TerserPlugin({ parallel: true }),
        new OptimizeCSSAssetsPlugin({})
      ]
    },

    plugins: [
      new MiniCssExtractPlugin({ filename: '../styles/main.css' }),
      new CopyWebpackPlugin({
        patterns: [{ from: 'static/', to: '../' }]
      })
    ]
  }
}
