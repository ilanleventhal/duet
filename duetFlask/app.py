from flask import Flask, render_template, url_for, request, redirect
from flask_sqlalchemy import SQLAlchemy
from spotify_client import *
import numpy as np
import pandas as pd

client_id = '657378f09f154f149c34d740f03930a6'
client_secret = 'fe91b9f0f7714cdabc485a8e4d9997d6'
spotify = SpotifyAPI(client_id, client_secret)

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///test.db'
db = SQLAlchemy(app)

class Todo(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    content = db.Column(db.String(200), nullable=False)
    date_created = db.Column(db.DateTime, default=datetime.datetime.utcnow)

    def __repr__(self):
        return '<Task %r>' % self.id


tdfs = []
userID = ""

@app.route('/', methods=['POST', 'GET'])
def index():
    if request.method == 'POST':
        userID = request.form['content']
        member = Todo(content=userID)

        try:
            db.session.add(member)
            db.session.commit()
            updf = pd.DataFrame((spotify.get_user_playlists(userID)['items']))
            utdf = pd.DataFrame()
            for i in range(0,len(updf)):
                utdf = pd.concat([utdf, pd.DataFrame.from_dict(spotify.get_playlist_tracks(updf.iloc[i,4]))], ignore_index=True)
            tdfs.append(utdf)
            print("length is", len(tdfs))
            return redirect('/')
        except:
            return 'There was an issue adding the party member'

    else:
        tasks = Todo.query.order_by(Todo.date_created).all()
        return render_template('index.html', tasks=tasks)


@app.route('/delete/<int:id>')
def delete(id):
    member_to_delete = Todo.query.get_or_404(id)

    try:
        db.session.delete(member_to_delete)
        db.session.commit()
        if tdfs:
            tdfs.remove(member_to_delete)
        print("length is", len(tdfs))
        return redirect('/')
    except:
        return 'There was a problem deleting the party member'

@app.route('/update/<int:id>', methods=['GET', 'POST'])
def update(id):
    task = Todo.query.get_or_404(id)

    if request.method == 'POST':
        task.content = request.form['content']

        try:
            db.session.commit()
            return redirect('/')
        except:
            return 'There was an issue updating your task'

    else:
        return render_template('update.html', task=task)

@app.route('/makePlaylist/', methods=['POST']) 
def makePlaylist():
    for i in range(0,len(tdfs)):
        tdfs[i]['ids'] = ''
        tdfs[i]['name'] = ''
    for i in range(0,len(tdfs)):
        for j in range(0,len(tdfs[i])):
            tdfs[i].iat[j,7] = tdfs[i].iat[j,1]['track']['id']
            tdfs[i].iat[j,8] = tdfs[i].iat[j,1]['track']['name']
    for i in range(0,len(tdfs)):
        tdfs[i] = tdfs[i].drop_duplicates(subset=['ids'])
    for i in range(0,len(tdfs)-1):
        ctdf = pd.concat([tdfs[i], tdfs[i+1]], ignore_index=True)
    mtdf = ctdf[ctdf.duplicated(['ids'])]
    mtdf.reset_index(drop=True)
    print(len(mtdf), "mutual songs sniped")
    print(spotify.create_playlist("ilanleventhal"))
    text = "made playlist"
    return render_template('index.html', msg=text)



if __name__ == "__main__":
    app.run(debug=True)