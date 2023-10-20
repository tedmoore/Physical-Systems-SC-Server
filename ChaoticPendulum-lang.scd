/*
Ted Moore

October 20, 2023

Formulae from: https://www.myphysicslab.com/pendulum/chaotic-pendulum-en.html
*/

s.boot;

(
fork({
	var win, uv, thetaDraw = 0, rDraw = 0, mDraw = 0;
	var synth;

	~cb = Bus.control(s,2);

	s.sync;

	~cb.setn([pi/2,0]);

	Window.closeAll;

	win = Window("Chaotic Pendulum",Rect(500,500,700,700));
	uv = UserView().drawFunc_{
		var origin = Point(uv.bounds.width/2,uv.bounds.height * 0.5);
		var scale = 200;
		var circleWidth, halfCircleWidth;

		var pt1 = origin + Point(sin(thetaDraw) * rDraw * scale,cos(thetaDraw) * rDraw * scale);

		Pen.line(origin,pt1);
		Pen.stroke;

		circleWidth = mDraw * scale * 0.2;
		halfCircleWidth = circleWidth / 2;

		Pen.circle(Rect(pt1.x-halfCircleWidth,pt1.y-halfCircleWidth,circleWidth,circleWidth));
		Pen.fill;
	};

	win.layout = VLayout(
		Button().states_([["Random Position"]]).action_{~cb.setn([0,0])},
		uv
	);

	~chaoticPendulum = {
		arg len = 1, gravity = 1, mass = 1, forceAmplitude = 0.01, damping = 0.5, forceFreq = 0.67;
		var theta, thetaP, thetaPP;
		var time = Sweep.kr;
		var preplus, num, den, torque, quotient;

		# theta, thetaP = In.kr(~cb,2);

		preplus = -1 * (gravity/len) * sin(theta);
		torque = forceAmplitude * cos(forceFreq * time);
		num = (-1 * damping * thetaP) + torque;
		den = mass * len * len;
		quotient = num/den;
		thetaPP = preplus + quotient;

		// [thetaPP,thetaP,theta].poll;

		thetaP = thetaP + thetaPP;
		theta = theta + thetaP;

		[quotient,thetaPP].poll;

		Out.kr(~cb,[theta,thetaP]);

		SendReply.kr(Impulse.kr(30),"/chaoticPendulum",[theta,len,mass]);

		[time,preplus,torque,num,den,quotient,thetaPP,thetaP,theta]
	};

	synth = ~chaoticPendulum.plot(5,separately:true);

	OSCdef(\chaoticPendulum,{
		arg msg;
		thetaDraw = msg[3];
		rDraw = msg[4];
		mDraw = msg[5];
		defer{uv.refresh};
	},"/chaoticPendulum");

	win.onClose_({synth.free});

	win.front;

},AppClock);
)