var webpack = require('webpack');
var path = require("path");
var BundleTracker = require('webpack-bundle-tracker');

const port = process.env.PORT || 3000;

module.exports = {
    context: __dirname,

    entry: {
        index: './src/index.js',
        vendors: ['react'],
    },

    output: {
        path: path.resolve("../main/static/main/js/bundles/"),
        filename: "[name]-[hash].js"
    },

    devtool: 'inline-source-map',
    
    module: {
        rules: [
            {
                test: /\.(js)$/,
                exclude: /node_modules/,
                use: ['babel-loader']
            }, 
            {
                test: /\.css$/,
                use: [
                    { loader: 'style-loader' },
                    { 
                        loader: 'css-loader',
                        options: {
                            modules: true,
                            localsConvention: 'camelCase',
                            sourceMap: true
                        }
                    }
                ]
            }
        ]
    },

    plugins: [
        new BundleTracker({filename: '../webpack-stats.json'})
    ],

    devServer: {
        host: 'localhost',
        port: port,
        historyApiFallback: true,
        open: true
    }
}
    /*

    externals: [],

    /*plugins: [
        new webpack.optimize.CommonsChunkPlugin('vendors', 'vendors.js')
    ],
    optimization: {
        runtimeChunk: "single",
        splitChunks: {
            cacheGroups: {
                vendor: {
                    test: /[\\/]node_modules[\\/]/,
                    name: "vendors",
                    chunks: "all"
                }
            }
        }
    },

    module: {
        loaders: []
    },

    resolve: {
        modulesDirectories: ['node_modules', 'bower_components'],
        extensions: ['', '.js', '.jsx']
    }
};*/