import "optimizer_types"
import "../nn_types"
import "../util"



-- | Plain vanilla gradient descent optimizer
--   with mean gradient
module GradientDescent (R:real) : trainer with t = R.t
                                          with alpha = R.t = {

  type t = R.t
  type alpha = t
  type loss_func 'o = {f:o -> o -> t, fd:o -> o -> o}

  module util = utility R

  let apply_grad (alpha:alpha)
                 (batch_size:i32)
                 ((w,b):(std_weights t))
                 ((wg,bg):(std_weights t)) =

      let wg_mean   = map (map R.((/i32 batch_size))) wg
      let bg_mean   = map (R.((/i32 batch_size))) bg

      let wg_scaled = util.scale_matrix wg_mean alpha
      let bg_scaled = util.scale_v bg_mean alpha

      let w'        = util.sub_matrix w wg_scaled
      let b'        = util.sub_v b bg_scaled
    in (w', b')

  let train [n] 'w 'g 'o 'e2 'i ({forward=f,
                                  backward=b,
                                  update=u,
                                  weights=w}:NN ([]i) w ([]o) g ([]o) e2 (apply_grad t))
                                (alpha:alpha)
                                (input:[n]i)
                                (labels:[n]o)
                                (batch_sz: i32)
                                ({f=_, fd=loss'}:loss_func o) =

    let i = 0
    let (w',_) = loop (w, i) while i < length input do
                   let input'          = input[i:i+batch_sz]
                   let label'          = labels[i:i+batch_sz]
                   let (cache, output) = f true w (input')
                   let error           = map2 (\o l -> loss' o l) output label'
                   let (_, grads)      = b false w cache error
                   let w'              = u (apply_grad alpha batch_sz) w grads
                   in (w', i + batch_sz)
    in {forward = f, backward = b, update = u, weights = w'}

}