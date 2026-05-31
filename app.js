const path = require('path');
const fs = require('fs');
const express = require('express');
const OS = require('os');
const mongoose = require("mongoose");
const app = express();
const cors = require('cors')

loadLocalEnv();

const PORT = process.env.PORT || 3000;
const localPlanets = require('./seed/planets.json');


app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '/')));
app.use(cors())

const mongoConfigured = Boolean(process.env.MONGO_URI);

if (mongoConfigured) {
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

    mongoose.connect(process.env.MONGO_URI, mongoOptions, function(err) {
        if (err) {
            console.error("MongoDB connection failed:", err.message);
            console.error("The app will continue using local fallback planet data.");
        } else {
            console.log("MongoDB connection successful");
        }
    })
} else {
    console.warn("MONGO_URI is not set. The app will use local fallback planet data.");
}

mongoose.connection.on('error', function(err) {
    console.error("MongoDB connection error:", err.message);
});

mongoose.connection.on('disconnected', function() {
    if (mongoConfigured) {
        console.warn("MongoDB disconnected. Planet lookups will use local fallback data until MongoDB is available.");
    }
});

function loadLocalEnv() {
    const envPath = path.join(__dirname, '.env');

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

var Schema = mongoose.Schema;

var dataSchema = new Schema({
    name: String,
    id: Number,
    description: String,
    image: String,
    velocity: String,
    distance: String
});
var planetModel = mongoose.model('planets', dataSchema);



app.post('/planet',   function(req, res) {
   // console.log("Received Planet ID " + req.body.id)
    const planetId = Number(req.body.id);

    if (Number.isNaN(planetId)) {
        return res.status(400).send({ error: "Planet id must be a number" });
    }

    const fallbackPlanet = localPlanets.find(function(planet) {
        return planet.id === planetId;
    });

    if (mongoose.connection.readyState !== 1) {
        if (fallbackPlanet) {
            return res.send(fallbackPlanet);
        }

        return res.status(404).send({ error: "Planet not found" });
    }

    planetModel.findOne({
        id: planetId
    }, function(err, planetData) {
        if (err) {
            console.error("Error fetching planet data:", err.message);
            return res.status(500).send({ error: "Error in Planet Data" });
        }

        if (planetData) {
            return res.send(planetData);
        }

        if (fallbackPlanet) {
            return res.send(fallbackPlanet);
        }

        return res.status(404).send({ error: "Planet not found" });
    })
})

app.get('/',   async (req, res) => {
    res.sendFile(path.join(__dirname, '/', 'index.html'));
});


app.get('/os',   function(req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "os": OS.hostname(),
        "env": process.env.NODE_ENV
    });
})

app.get('/live',   function(req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "status": "live"
    });
})

app.get('/ready',   function(req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "status": "ready"
    });
})

if (require.main === module) {
    app.listen(PORT, () => {
        console.log("Server successfully running on port - " + PORT);
    })
}


module.exports = app;
