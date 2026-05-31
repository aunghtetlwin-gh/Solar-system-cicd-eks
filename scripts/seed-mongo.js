const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const planets = require('../seed/planets.json');

loadLocalEnv();

const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/solar-system';

const planetSchema = new mongoose.Schema({
    name: String,
    id: Number,
    description: String,
    image: String,
    velocity: String,
    distance: String
});

const Planet = mongoose.model('planets', planetSchema, 'planets');

async function seedMongo() {
    const mongoOptions = {
        useNewUrlParser: true,
        useUnifiedTopology: true
    };

    if (process.env.MONGO_USERNAME) {
        mongoOptions.user = process.env.MONGO_USERNAME;
    }

    if (process.env.MONGO_PASSWORD) {
        mongoOptions.pass = process.env.MONGO_PASSWORD;
    }

    await mongoose.connect(mongoUri, mongoOptions);
    await Planet.deleteMany({});
    await Planet.insertMany(planets);

    console.log(`Seeded ${planets.length} planets into ${mongoUri}`);
}

function loadLocalEnv() {
    const envPath = path.join(__dirname, '..', '.env');

    if (!fs.existsSync(envPath)) {
        return;
    }

    const envFile = fs.readFileSync(envPath, 'utf8');

    envFile.split(/\r?\n/).forEach(function(line) {
        const trimmedLine = line.trim();

        if (!trimmedLine || trimmedLine.startsWith('#')) {
            return;
        }

        const separatorIndex = trimmedLine.indexOf('=');

        if (separatorIndex === -1) {
            return;
        }

        const key = trimmedLine.slice(0, separatorIndex).trim();
        let value = trimmedLine.slice(separatorIndex + 1).trim();

        if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
            value = value.slice(1, -1);
        }

        if (!Object.prototype.hasOwnProperty.call(process.env, key)) {
            process.env[key] = value;
        }
    });
}

seedMongo()
    .catch(function(err) {
        console.error('MongoDB seed failed:', err.message);
        process.exitCode = 1;
    })
    .finally(function() {
        mongoose.connection.close();
    });
