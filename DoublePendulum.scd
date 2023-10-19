/*
Ted Moore

October 14, 2023

video demo: https://www.loom.com/share/12c6cdb7dfd14332af6fe73ea11ac729

Inspired by: https://www.youtube.com/watch?v=uWzPe_S-RVE

Formulae from: https://myphysicslab.com/pendulum/double-pendulum-en.html
*/

s.boot;

(
fork({
	var win, uv, x1draw = 0, y1draw = 0, x2draw = 0, y2draw = 0, m1draw = 0, m2draw = 0;
	var synth;

	~cb = Bus.control(s,4);

	s.sync;

	~cb.setn([rand(-pi/2,pi/2),rand(-pi/2,pi/2),0,0]);

	Window.closeAll;

	win = Window("Double Pendulum",Rect(500,500,700,700));
	uv = UserView().drawFunc_{
		var origin = Point(uv.bounds.width/2,uv.bounds.height * 0.5);
		var circleWidth, halfCircleWidth;

		var pt1 = origin + Point(x1draw,y1draw);
		var pt2 = origin + Point(x2draw,y2draw);

		Pen.line(origin,pt1);
		Pen.line(pt1,pt2);
		Pen.stroke;

		circleWidth = m1draw;
		halfCircleWidth = circleWidth / 2;

		Pen.circle(Rect(pt1.x-halfCircleWidth,pt1.y-halfCircleWidth,circleWidth,circleWidth));

		circleWidth = m2draw;
		halfCircleWidth = circleWidth / 2;

		Pen.circle(Rect(pt2.x-halfCircleWidth,pt2.y-halfCircleWidth,circleWidth,circleWidth));
		Pen.fill;
	};

	win.layout = VLayout(
		Button().states_([["Random Position"]]).action_{~cb.setn([rand(-pi/2,pi/2),rand(-pi/2,pi/2),0,0])},
		uv
	);

	~doublePendulum = {
		arg g = 2, m1 = 40, m2 = 40, r1 = 100, r2 = 100, throttle = 0.003, dampening = 0.9999;
		var a1, a2, num1, num2, num3, num4, den, a1_a = 0, a2_a = 0, a1_v = 0, a2_v = 0, x1, y1, x2, y2;

		# a1, a2, a1_v, a2_v = In.kr(~cb,4);

		num1 = -1 * g * ((2*m1) + m2) * sin(a1);
		num2 = -1 * m2 * g * sin(a1-(2*a2));
		num3 = -2 * sin(a1-a2) * m2;
		num4 = (a2_v.pow(2) * r2) + (a1_v.pow(2) * r1 * cos(a1-a2));
		den = r1 * ((2 * m1) + m2 - (m2 * cos((2*a1)-(2*a2))));
		a1_a = (num1 + num2 + (num3 * num4)) / den;

		num1 = 2 * sin(a1-a2);
		num2 = a1_v.pow(2) * r1 * (m1+m2);
		num3 = g * (m1 + m2) * cos(a1);
		num4 = a2_v.pow(2) * r2 * m2 * cos(a1-a2);
		den = r2 * ((2 * m1) + m2 - (m2 * cos((2*a1)-(2*a2))));
		a2_a = (num1 * (num2 + num3 + num4)) / den;

		a1_a = a1_a * throttle;
		a2_a = a2_a * throttle;

		a1_v = a1_v + a1_a;
		a2_v = a2_v + a2_a;

		a1_v = a1_v * dampening;
		a2_v = a2_v * dampening;

		a1 = a1 + a1_v;
		a2 = a2 + a2_v;

		x1 = r1 * sin(a1);
		y1 = r1 * cos(a1);
		x2 = x1 + (r2 * sin(a2));
		y2 = y1 + (r2 * cos(a2));

		x2.linlin(-1 * (r1+r2),r1+r2,0,1);

		Out.kr(~cb,[a1, a2, a1_v, a2_v]);

		SendReply.kr(Impulse.kr(30),"/doublePendulum",[x1,y1,x2,y2,m1,m2]);

		SinOsc.ar(x1.linlin(-1 * r1,r1,80,1000) * 2.pow(SinOsc.ar(x2.linlin(-1 * (r1+r2),r1+r2,20,500)) * 5 * y2.linlin(-1 * (r1+r2),r1+r2,0,1))).dup;
	};

	synth = ~doublePendulum.play;

	OSCdef(\doublePendulum,{
		arg msg;
		# x1draw, y1draw, x2draw, y2draw, m1draw, m2draw = msg[3..];
		defer{uv.refresh};
	},"/doublePendulum");

	win.onClose_({synth.free});

	win.front;

},AppClock);
)